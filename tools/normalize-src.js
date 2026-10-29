// Normalizes ext_resource ids in decompiled .tres/.tscn files so that diffs between game versions stay small.
// GDRE numbers the ids sequentially, so one added resource renumbers every id and reference after it.
// Each id becomes the resource uid and the ext_resource block is sorted by path.
// Also keeps the committed text of Transform3D properties that only differ by float noise and the committed sub_resource ids that GDRE regenerates randomly, so diffs show real changes only.
// Usage: node tools/normalize-src.js [dir]    (dir defaults to src/)
const fs = require('fs');
const path = require('path');
const cp = require('child_process');
const crypto = require('crypto');

const root = path.resolve(process.argv[2] || path.join(__dirname, '..', 'src'));
const header = /^\[ext_resource .*\bid="([^"]+)"\]\s*$/;

// Returns null when the derived ids would collide, leaving the file for manual inspection.
function normalize(text) {
	const ids = new Map();
	const taken = new Set();
	const out = [];
	let block = [];
	for (const line of text.split('\n')) {
		const m = header.exec(line);
		if (!m) {
			if (block.length) {
				block.sort((a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0));
				for (const entry of block) out.push(entry.line);
				block = [];
			}
			out.push(line.replace(/ExtResource\("([^"]+)"\)/g, (ref, id) => (ids.has(id) ? `ExtResource("${ids.get(id)}")` : ref)));
			continue;
		}
		const key = /\bpath="([^"]*)"/.exec(line)?.[1] ?? '';
		const id = /\buid="uid:\/\/([^"]+)"/.exec(line)?.[1] ?? key;
		if (!id || taken.has(id) || ids.has(m[1])) return null;
		taken.add(id);
		ids.set(m[1], id);
		block.push({ key, line: line.replace(/\bid="[^"]+"\]/, () => `id="${id}"]`) });
	}
	for (const entry of block) out.push(entry.line);
	return out.join('\n');
}

// GDRE re-derives transforms (mostly skeleton rest poses) with float noise of about 1e-5 on every decompile.
// A Transform3D property whose components all stay within this distance of the committed value keeps the committed text.
const transformTolerance = 1e-3;
const transformLine = /^([\w\/.:-]+) = Transform3D\(([^)]*)\)\s*$/;

// Sections are keyed so that header attributes which change between versions (unique_id, node_paths, groups) do not break the match.
function sectionKey(header) {
	if (!header.startsWith('[node ')) return header;
	return `node|${/\bname="([^"]*)"/.exec(header)?.[1]}|${/\bparent="([^"]*)"/.exec(header)?.[1] ?? ''}`;
}

// Maps section key to a map of property name to Transform3D line. Duplicate section keys are ambiguous and dropped.
function indexTransforms(text) {
	const sections = new Map();
	let props = null;
	for (const line of text.split('\n')) {
		if (line.startsWith('[')) {
			const key = sectionKey(line);
			props = sections.has(key) ? null : new Map();
			sections.set(key, props);
			continue;
		}
		const m = props && transformLine.exec(line);
		if (m) props.set(m[1], line);
	}
	return sections;
}

function restoreNoisyTransforms(text, oldText) {
	const old = indexTransforms(oldText);
	let props = null;
	let restored = 0;
	const out = text.split('\n').map((line) => {
		if (line.startsWith('[')) {
			props = old.get(sectionKey(line)) ?? null;
			return line;
		}
		const m = props && transformLine.exec(line);
		const oldLine = m && props.get(m[1]);
		if (!oldLine || oldLine === line) return line;
		const a = m[2].split(',').map(Number);
		const b = transformLine.exec(oldLine)[2].split(',').map(Number);
		if (a.length !== b.length || a.some((v, i) => !(Math.abs(v - b[i]) <= transformTolerance))) return line;
		restored++;
		return oldLine;
	});
	return { text: out.join('\n'), restored };
}

// Godot assigns random sub_resource ids to resources saved without one, so they change on every decompile.
// Per type, ids absent from HEAD take the HEAD ids that vanished, in order of appearance. Types whose unmatched counts differ are left alone.
function restoreSubResourceIds(text, oldText) {
	const header = /^\[sub_resource type="([^"]+)" id="([^"]+)"\]/gm;
	const collect = (src) => {
		const byType = new Map();
		for (const m of src.matchAll(header)) {
			if (!byType.has(m[1])) byType.set(m[1], []);
			byType.get(m[1]).push(m[2]);
		}
		return byType;
	};
	const now = collect(text);
	const before = collect(oldText);
	const renames = new Map();
	for (const [type, ids] of now) {
		const gone = (before.get(type) ?? []).filter((id) => !ids.includes(id));
		const fresh = ids.filter((id) => !(before.get(type) ?? []).includes(id));
		if (gone.length !== fresh.length) continue;
		fresh.forEach((id, i) => renames.set(id, gone[i]));
	}
	if (!renames.size) return { text, restored: 0 };
	const swap = (id) => renames.get(id) ?? id;
	const out = text
		.replace(header, (line, type, id) => `[sub_resource type="${type}" id="${swap(id)}"]`)
		.replace(/SubResource\("([^"]+)"\)/g, (ref, id) => `SubResource("${swap(id)}")`);
	return { text: out, restored: renames.size };
}

const git = (args, input) => cp.spawnSync('git', ['-C', root, ...args], { input, maxBuffer: 1 << 30 });
const blobSha = (text) => crypto.createHash('sha1').update(`blob ${Buffer.byteLength(text, 'latin1')}\0`).update(text, 'latin1').digest('hex');

// HEAD blob sha per tracked path (relative to root, forward slashes).
const headShas = new Map();
for (const entry of git(['ls-tree', '-r', '-z', 'HEAD']).stdout.toString('latin1').split('\0')) {
	const m = /^\d+ blob (\w+)\t(.*)$/s.exec(entry);
	if (m) headShas.set(m[2], m[1]);
}

// Reads the HEAD text of the given paths, a chunk per git process to stay under the output buffer limit.
function* readHead(rels) {
	for (let i = 0; i < rels.length; i += 20) {
		const chunk = rels.slice(i, i + 20);
		const buf = git(['cat-file', '--batch'], chunk.map((rel) => `HEAD:${rel}\n`).join('')).stdout;
		let pos = 0;
		for (const rel of chunk) {
			const eol = buf.indexOf(10, pos);
			const size = Number(buf.toString('latin1', pos, eol).split(' ')[2]);
			yield [rel, buf.toString('latin1', eol + 1, eol + 1 + size)];
			pos = eol + 1 + size + 1;
		}
	}
}

const files = fs.readdirSync(root, { recursive: true, withFileTypes: true })
	.filter((entry) => entry.isFile() && /\.(tres|tscn)$/.test(entry.name))
	.map((entry) => path.join(entry.parentPath, entry.name));

let scanned = 0;
let changed = 0;
let skipped = 0;
let restored = 0;
let idsKept = 0;
const touched = new Set();
const differing = [];
for (const file of files) {
	// latin1 round-trips every byte, so anything outside the rewritten ASCII tokens is preserved exactly.
	const text = fs.readFileSync(file, 'latin1');
	const result = normalize(text);
	scanned++;
	if (result === null) {
		skipped++;
		console.warn(`skipped (id collision): ${path.relative(root, file)}`);
		continue;
	}
	const rel = path.relative(root, file).split(path.sep).join('/');
	if (headShas.has(rel) && headShas.get(rel) !== blobSha(result)) differing.push(rel);
	if (result === text) continue;
	fs.writeFileSync(file, result, 'latin1');
	touched.add(rel);
	changed++;
}

// Only files that still differ from HEAD can carry noise, so only those are compared against it.
for (const [rel, head] of readHead(differing)) {
	const file = path.join(root, rel);
	const text = fs.readFileSync(file, 'latin1');
	const ids = restoreSubResourceIds(text, head);
	let result = ids.text;
	idsKept += ids.restored;
	if (result.includes(' = Transform3D(')) {
		const r = restoreNoisyTransforms(result, head);
		result = r.text;
		restored += r.restored;
	}
	if (result === text) continue;
	fs.writeFileSync(file, result, 'latin1');
	if (!touched.has(rel)) changed++;
}
console.log(`${root}: scanned ${scanned}, changed ${changed}, skipped ${skipped}, transforms kept from HEAD ${restored}, sub_resource ids kept from HEAD ${idsKept}`);
