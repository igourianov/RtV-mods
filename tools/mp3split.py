#!/usr/bin/env python3
"""
mp3split - split one large MP3 into per-track files using a playlist.

Each playlist entry gives a title and an APPROXIMATE start time. The real cut
is snapped to the quietest gap (detected silence) near that timestamp, so cuts
land between tracks instead of mid-note. Splitting is lossless (ffmpeg stream
copy); no re-encode.

Requires ffmpeg + ffprobe on PATH (or passed via --ffmpeg / --ffprobe).

Playlist format (UTF-8 text), one track per line:
    <timestamp><whitespace or |><title>
where <timestamp> is SS(.ms) | MM:SS | H:MM:SS, e.g.
    0:00   First Track
    2:23   Second Track
    327    Third Track            # plain seconds also accepted
Blank lines and lines starting with '#' are ignored.

Example:
    python mp3split.py -i big.mp3 -p playlist.txt -o out
    python mp3split.py -i big.mp3 -p playlist.txt -o out --dry-run
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys


SILENCE_START_RE = re.compile(r"silence_start:\s*([0-9]+\.?[0-9]*)")
SILENCE_END_RE = re.compile(
	r"silence_end:\s*([0-9]+\.?[0-9]*)\s*\|\s*silence_duration:\s*([0-9]+\.?[0-9]*)"
)
TIMESTAMP_RE = re.compile(r"^\s*([0-9]+(?::[0-9]{1,2}){0,2}(?:\.[0-9]+)?)\s*[|\t ]\s*(.+?)\s*$")
ILLEGAL_FS_CHARS = re.compile(r'[<>:"/\\|?*\x00-\x1f]')


def die(msg):
	print(f"error: {msg}", file=sys.stderr)
	sys.exit(1)


def parse_timestamp(token):
	"""SS(.ms) | MM:SS | H:MM:SS -> float seconds."""
	parts = token.split(":")
	if len(parts) > 3:
		raise ValueError(f"bad timestamp: {token!r}")
	parts = [float(p) for p in parts]
	seconds = 0.0
	for p in parts:
		seconds = seconds * 60.0 + p
	return seconds


def parse_playlist(path):
	"""-> list of dicts {title, start} sorted by start."""
	tracks = []
	with open(path, "r", encoding="utf-8-sig") as fh:
		for lineno, raw in enumerate(fh, 1):
			line = raw.rstrip("\n")
			if not line.strip() or line.lstrip().startswith("#"):
				continue
			m = TIMESTAMP_RE.match(line)
			if not m:
				die(f"playlist line {lineno}: cannot parse {line!r}")
			start = parse_timestamp(m.group(1))
			tracks.append({"title": m.group(2).strip(), "start": start})
	if not tracks:
		die("playlist has no tracks")
	tracks.sort(key=lambda t: t["start"])
	return tracks


def probe_duration(ffprobe, path):
	out = subprocess.run(
		[ffprobe, "-v", "error", "-show_entries", "format=duration",
		 "-of", "default=nokey=1:noprint_wrappers=1", path],
		capture_output=True, text=True, encoding="utf-8", errors="replace",
	)
	if out.returncode != 0:
		die(f"ffprobe failed:\n{out.stderr.strip()}")
	try:
		return float(out.stdout.strip())
	except ValueError:
		die(f"could not read duration from ffprobe output: {out.stdout!r}")


def detect_silences(ffmpeg, path, threshold_db, min_silence, total):
	"""Run silencedetect once over the file -> list of (start, end) intervals."""
	proc = subprocess.run(
		[ffmpeg, "-hide_banner", "-nostats", "-i", path,
		 "-af", f"silencedetect=noise={threshold_db}dB:d={min_silence}",
		 "-f", "null", "-"],
		capture_output=True, text=True, encoding="utf-8", errors="replace",
	)
	silences = []
	pending = None
	for line in proc.stderr.splitlines():
		ms = SILENCE_START_RE.search(line)
		if ms:
			pending = float(ms.group(1))
			continue
		me = SILENCE_END_RE.search(line)
		if me and pending is not None:
			silences.append((pending, float(me.group(1))))
			pending = None
	if pending is not None:
		# file ended while still silent
		silences.append((pending, total))
	return silences


def snap_to_silence(target, silences, window):
	"""
	Pick the silence interval nearest 'target' within 'window' seconds.
	Returns (cut_point, silence_interval) or (None, None) if nothing in range.
	Cut lands inside the gap: at target if target is within a silence, else at
	the silence center.
	"""
	best = None
	best_dist = None
	for s, e in silences:
		if s <= target <= e:
			dist = 0.0
		else:
			dist = min(abs(target - s), abs(target - e))
		if dist <= window and (best_dist is None or dist < best_dist):
			best_dist = dist
			best = (s, e)
	if best is None:
		return None, None
	s, e = best
	cut = target if s <= target <= e else (s + e) / 2.0
	return cut, best


def sanitize_filename(name, maxlen=150):
	name = ILLEGAL_FS_CHARS.sub("", name)
	name = re.sub(r"\s+", " ", name).strip().rstrip(". ")
	if len(name) > maxlen:
		name = name[:maxlen].rstrip()
	return name or "track"


def fmt_ts(seconds):
	m, s = divmod(seconds, 60)
	h, m = divmod(int(m), 60)
	return f"{h:d}:{m:02d}:{s:06.3f}" if h else f"{m:d}:{s:06.3f}"


def build_plan(tracks, silences, total, window, snap):
	"""Resolve each track start to an actual cut point; return enriched plan."""
	n = len(tracks)
	plan = []
	for i, t in enumerate(tracks):
		req = t["start"]
		note = ""
		if not snap or req <= 0.0:
			cut = req
			if req > 0.0 and not snap:
				note = "literal (snap off)"
		else:
			cut, interval = snap_to_silence(req, silences, window)
			if cut is None:
				cut = req
				note = f"NO SILENCE within {window:g}s, used literal"
			else:
				note = f"gap [{fmt_ts(interval[0])}..{fmt_ts(interval[1])}]"
		plan.append({"title": t["title"], "requested": req, "cut": cut, "note": note})

	# enforce strictly increasing cut points
	for i in range(1, n):
		if plan[i]["cut"] <= plan[i - 1]["cut"]:
			die(f"cut points not increasing at track {i + 1} "
				f"({plan[i]['title']!r}: {fmt_ts(plan[i]['cut'])} <= "
				f"{fmt_ts(plan[i - 1]['cut'])}). Lower --window or fix playlist.")

	for i in range(n):
		end = plan[i + 1]["cut"] if i + 1 < n else total
		plan[i]["start"] = plan[i]["cut"]
		plan[i]["end"] = end
		plan[i]["duration"] = end - plan[i]["cut"]
	return plan


def print_plan(plan):
	print(f"{'#':>2}  {'requested':>10}  {'cut':>10}  {'dur':>9}  {'delta':>7}  title / note")
	print("-" * 92)
	for i, p in enumerate(plan, 1):
		delta = p["cut"] - p["requested"]
		print(f"{i:>2}  {fmt_ts(p['requested']):>10}  {fmt_ts(p['cut']):>10}  "
			f"{fmt_ts(p['duration']):>9}  {delta:>+7.2f}  {p['title']}")
		if p["note"]:
			print(f"{'':>38}  -> {p['note']}")


def codec_args(enc):
	"""Build the ffmpeg output codec args. enc=None -> lossless stream copy."""
	if not enc:
		return ["-c", "copy", "-avoid_negative_ts", "make_zero",
				"-reset_timestamps", "1"]
	args = ["-c:a", "libmp3lame"]
	if enc.get("bitrate"):
		args += ["-b:a", enc["bitrate"]]
	if enc.get("mono"):
		args += ["-ac", "1"]
	if enc.get("samplerate"):
		args += ["-ar", str(enc["samplerate"])]
	return args


def split_file(ffmpeg, src, plan, outdir, pad, enc):
	os.makedirs(outdir, exist_ok=True)
	for i, p in enumerate(plan, 1):
		name = f"{str(i).zfill(pad)} - {sanitize_filename(p['title'])}.mp3"
		dst = os.path.join(outdir, name)
		cmd = [
			ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
			"-ss", f"{p['start']:.3f}", "-i", src,
			"-t", f"{p['duration']:.3f}",
			"-map", "0:a", *codec_args(enc),
			dst,
		]
		res = subprocess.run(cmd, capture_output=True, text=True,
							encoding="utf-8", errors="replace")
		if res.returncode != 0:
			die(f"ffmpeg failed on track {i} ({name}):\n{res.stderr.strip()}")
		print(f"  wrote {name}")
		p["file"] = name


def main():
	ap = argparse.ArgumentParser(
		description="Split one MP3 into per-track files, snapping cuts to silence.",
		formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
	ap.add_argument("-i", "--input", required=True, help="source MP3")
	ap.add_argument("-p", "--playlist", required=True, help="playlist text file")
	ap.add_argument("-o", "--outdir", default="out", help="output directory (default: out)")
	ap.add_argument("--window", type=float, default=15.0,
					help="seconds to search around each timestamp for a gap (default: 15)")
	ap.add_argument("--threshold", type=float, default=-30.0,
					help="silence noise floor in dB (default: -30)")
	ap.add_argument("--min-silence", type=float, default=0.3,
					help="minimum gap length in seconds (default: 0.3)")
	ap.add_argument("--no-snap", action="store_true",
					help="cut at literal timestamps, ignore silence")
	ap.add_argument("--bitrate",
					help="re-encode (libmp3lame) at this audio bitrate, e.g. 64k")
	ap.add_argument("--mono", action="store_true",
					help="downmix to mono (triggers re-encode)")
	ap.add_argument("--samplerate", type=int,
					help="output sample rate in Hz, e.g. 22050 (triggers re-encode)")
	ap.add_argument("--dry-run", action="store_true",
					help="print the plan, write nothing")
	ap.add_argument("--manifest", help="write resolved tracks to this JSON file")
	ap.add_argument("--ffmpeg", default=shutil.which("ffmpeg"), help="path to ffmpeg")
	ap.add_argument("--ffprobe", default=shutil.which("ffprobe"), help="path to ffprobe")
	args = ap.parse_args()

	# titles are often non-ASCII (Cyrillic); avoid cp1252 console crashes
	for stream in (sys.stdout, sys.stderr):
		try:
			stream.reconfigure(encoding="utf-8")
		except (AttributeError, ValueError):
			pass

	if not args.ffmpeg or not args.ffprobe:
		die("ffmpeg/ffprobe not found on PATH. Install with:\n"
			"  winget install Gyan.FFmpeg\n"
			"then reopen the shell, or pass --ffmpeg / --ffprobe paths.")
	if not os.path.isfile(args.input):
		die(f"input not found: {args.input}")

	enc = None
	if args.bitrate or args.mono or args.samplerate:
		enc = {"bitrate": args.bitrate, "mono": args.mono,
			   "samplerate": args.samplerate}

	tracks = parse_playlist(args.playlist)
	total = probe_duration(args.ffprobe, args.input)
	print(f"source: {args.input}  ({fmt_ts(total)}, {len(tracks)} tracks)")
	if enc:
		bits = enc["bitrate"] or "lame default"
		chans = "mono" if enc["mono"] else "stereo"
		sr = f"{enc['samplerate']}Hz" if enc["samplerate"] else "source rate"
		print(f"encode: libmp3lame {bits}, {chans}, {sr}")
	else:
		print("encode: lossless stream copy")

	if args.no_snap:
		silences = []
	else:
		print(f"detecting silence (noise={args.threshold}dB, d={args.min_silence}s) ...")
		silences = detect_silences(args.ffmpeg, args.input, args.threshold,
									args.min_silence, total)
		print(f"  found {len(silences)} silence interval(s)")

	plan = build_plan(tracks, silences, total, args.window, not args.no_snap)
	print()
	print_plan(plan)
	print()

	if args.manifest:
		manifest = [
			{"index": i + 1, "title": p["title"], "file": p.get("file"),
			 "start": round(p["start"], 3), "duration": round(p["duration"], 3),
			 "requested": round(p["requested"], 3)}
			for i, p in enumerate(plan)
		]

	if args.dry_run:
		print("dry run: no files written.")
	else:
		pad = max(2, len(str(len(plan))))
		split_file(args.ffmpeg, args.input, plan, args.outdir, pad, enc)
		print(f"\ndone -> {os.path.abspath(args.outdir)}")

	if args.manifest:
		# refresh filenames after split
		manifest = [
			{"index": i + 1, "title": p["title"], "file": p.get("file"),
			 "start": round(p["start"], 3), "duration": round(p["duration"], 3),
			 "requested": round(p["requested"], 3)}
			for i, p in enumerate(plan)
		]
		with open(args.manifest, "w", encoding="utf-8") as fh:
			json.dump(manifest, fh, ensure_ascii=False, indent=2)
		print(f"manifest -> {args.manifest}")


if __name__ == "__main__":
	main()
