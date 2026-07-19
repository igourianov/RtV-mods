#!/usr/bin/env node
// Markdown -> Nexus BBCode.
//   node md2bb.mjs <file.md>   writes <file>.bb.txt beside the source
//   node md2bb.mjs             reads stdin, writes stdout

import { readFileSync, writeFileSync, existsSync, statSync } from "node:fs";
import { dirname, join, basename, extname } from "node:path";
import { Marked } from "marked";

// Metric-compatible across Windows/macOS/Linux. Consolas is Windows-only and
// silently falls back to the proportional body font elsewhere.
const CODE_FONT = "Courier New";
const HEADING_SIZE = { 1: 6, 2: 5, 3: 4, 4: 3, 5: 3, 6: 3 };

const warnings = [];


function inline(tokens, parser) {
	return parser.parseInline(tokens);
}


// marked escapes for HTML output; BBCode is plain text so it has to come back out.
function decode(text) {
	return text
		.replace(/&#(\d+);/g, (_, code) => String.fromCharCode(code))
		.replace(/&quot;/g, "\"")
		.replace(/&lt;/g, "<")
		.replace(/&gt;/g, ">")
		.replace(/&amp;/g, "&");
}


function block(text) {
	return text.replace(/\n{3,}/g, "\n\n").trim();
}


const renderer = {
	heading({ tokens, depth }) {
		const size = HEADING_SIZE[depth];
		return `[size=${size}][b]${inline(tokens, this.parser)}[/b][/size]\n\n`;
	},

	paragraph({ tokens }) {
		return `${inline(tokens, this.parser)}\n\n`;
	},

	strong({ tokens }) {
		return `[b]${inline(tokens, this.parser)}[/b]`;
	},

	em({ tokens }) {
		return `[i]${inline(tokens, this.parser)}[/i]`;
	},

	del({ tokens }) {
		return `[s]${inline(tokens, this.parser)}[/s]`;
	},

	codespan({ text }) {
		return `[font=${CODE_FONT}]${decode(text)}[/font]`;
	},

	code({ text }) {
		return `[code]${decode(text)}[/code]\n\n`;
	},

	text(token) {
		return token.tokens ? inline(token.tokens, this.parser) : decode(token.text);
	},

	link({ href, tokens }) {
		return `[url=${href}]${inline(tokens, this.parser)}[/url]`;
	},

	image({ href }) {
		return `[img]${href}[/img]`;
	},

	blockquote({ tokens }) {
		return `[quote]${block(this.parser.parse(tokens))}[/quote]\n\n`;
	},

	hr() {
		return "[line]\n\n";
	},

	list(token) {
		const tag = token.ordered ? `[list=${token.start || 1}]` : "[list]";
		const items = token.items.map(item => this.listitem(item)).join("");
		return `${tag}\n${items}[/list]\n`;
	},

	listitem(item) {
		// Loose items arrive wrapped in paragraphs; block() strips the padding
		// so nested lists stay attached to their parent bullet. Tight items emit
		// their nested list with no separator, hence the explicit break.
		const body = block(this.parser.parse(item.tokens)).replace(/(\S)\[list/g, "$1\n[list");
		return `[*]${body}\n`;
	},

	table(token) {
		warnings.push("table flattened - Nexus BBCode has no table tag");
		const row = cells => cells.map(c => inline(c.tokens, this.parser)).join(" | ");
		const lines = [row(token.header), ...token.rows.map(row)];
		return `${lines.join("\n")}\n\n`;
	},

	html({ text }) {
		warnings.push("raw HTML passed through unchanged");
		return text;
	},

	br() {
		return "\n";
	},

	checkbox() {
		return "";
	}
};

const marked = new Marked({ gfm: true, renderer });


function convert(md) {
	// Nexus renders lists with a generous margin, so the blank line the preceding
	// block leaves behind wastes vertical space. The trailing gap is dropped by the
	// list renderer itself.
	const bb = block(marked.parse(md)).replace(/\n\n\[list/g, "\n[list");
	return `${bb}\n`;
}


const [, , arg] = process.argv;

if (arg) {
	if (!existsSync(arg) || !statSync(arg).isFile()) {
		console.error(`Not a file: ${arg}`);
		process.exit(1);
	}

	const out = join(dirname(arg), `${basename(arg, extname(arg))}.bb.txt`);
	writeFileSync(out, convert(readFileSync(arg, "utf8")), "utf8");
	console.log(out);
} else {
	process.stdout.write(convert(readFileSync(0, "utf8")));
}

for (const w of new Set(warnings)) {
	console.error(`warning: ${w}`);
}
