// Normalizes ext_resource ids in decompiled .tres/.tscn files so that diffs between game versions stay small.
// GDRE numbers the ids sequentially, so one added resource renumbers every id and reference after it.
// Each id becomes the resource uid and the ext_resource block is sorted by path.
// Usage: node tools/normalize-src.js [dir]    (dir defaults to src/)
const fs = require('fs');
const path = require('path');

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

let scanned = 0;
let changed = 0;
let skipped = 0;
for (const entry of fs.readdirSync(root, { recursive: true, withFileTypes: true })) {
	if (!entry.isFile() || !/\.(tres|tscn)$/.test(entry.name)) continue;
	const file = path.join(entry.parentPath, entry.name);
	// latin1 round-trips every byte, so anything outside the rewritten ASCII tokens is preserved exactly.
	const text = fs.readFileSync(file, 'latin1');
	const result = normalize(text);
	scanned++;
	if (result === null) {
		skipped++;
		console.warn(`skipped (id collision): ${path.relative(root, file)}`);
		continue;
	}
	if (result === text) continue;
	fs.writeFileSync(file, result, 'latin1');
	changed++;
}
console.log(`${root}: scanned ${scanned}, changed ${changed}, skipped ${skipped}`);
