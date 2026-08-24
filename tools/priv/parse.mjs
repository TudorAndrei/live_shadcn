// Reads a `.tsx` and prints its syntax tree as JSON.
//
// This is the whole of the JavaScript in the pipeline, and it decides nothing.
// `oxc-parser` produces an ESTree-shaped tree with an offset on every node, and
// `LiveShadcnTools.Ast` reads that tree and slices the source with those
// offsets. What an expression means stays an Elixir decision, reviewable in one
// language, the way every other stage is.
//
// The source arrives as a file, because the parser reads to end of input and an
// Erlang port has no way to say the input ended without ending the process as
// well. The filename matters only for its extension — TSX is a parsing mode,
// not a fact about where the bytes came from.
//
//     node priv/parse.mjs some.tsx
//
// Prints the tree on stdout. A syntax error is a non-zero exit and a message on
// stderr, because a file this cannot parse is a file nothing downstream should
// guess at.
//
// ── Offsets are converted, and that is the one thing this file does ──
//
// The node bindings count offsets in UTF-16 code units, because that is what a
// JavaScript string is indexed by. Elixir slices bytes. Every offset is
// converted here, once, rather than in Elixir per node — the conversion needs
// one pass over the source and a table, and this is the side that has both.
//
// It matters for one character in a file and then for everything after it: an
// em dash in a comment on line four moved every slice below it by two bytes,
// and what came out was `costText="xt={inputCost"` — plausible-looking markup
// with no error anywhere.

import { readFileSync } from "node:fs";
import { parseSync, visitorKeys } from "oxc-parser";
import { ScopeTracker, isReferenceIdentifier, walk } from "oxc-walker";

const path = process.argv[2];

if (!path) {
  process.stderr.write("usage: node priv/parse.mjs <file.tsx>\n");
  process.exit(2);
}

const source = readFileSync(path, "utf8");
const { program, module, errors } = parseSync(path, source);

if (errors.length > 0) {
  process.stderr.write(errors.map((error) => error.message).join("\n") + "\n");
  process.exit(1);
}

// utf16 index -> utf8 byte offset, for every position in the source.
const toBytes = new Uint32Array(source.length + 1);

for (let i = 0, bytes = 0; i <= source.length; i++) {
  toBytes[i] = bytes;

  if (i < source.length) {
    const point = source.codePointAt(i);

    if (point <= 0x7f) bytes += 1;
    else if (point <= 0x7ff) bytes += 2;
    else if (point <= 0xffff) bytes += 3;
    else {
      // Outside the basic plane: one code point, two UTF-16 units, four bytes.
      bytes += 4;
      toBytes[++i] = bytes;
    }
  }
}

const convert = (node) => {
  if (node === null || typeof node !== "object") return;

  if (typeof node.start === "number") node.start = toBytes[node.start];
  if (typeof node.end === "number") node.end = toBytes[node.end];

  for (const key of visitorKeys[node.type] ?? []) {
    const child = node[key];

    if (Array.isArray(child)) child.forEach(convert);
    else convert(child);
  }
};

// A prop can be named in a component signature and never reach the render.
// The old reader searched generated source text for a matching word. Use the
// parser's scope graph instead. A parameter reference belongs to the component
// only while that parameter's function is active; a nested event handler does
// not make the parameter a render input.
const parameterReferences = [];
const scopes = new ScopeTracker({ preserveExitedScopes: true });
const functionStack = [];

const functionNode = (node) =>
  node.type === "FunctionDeclaration" ||
  node.type === "FunctionExpression" ||
  node.type === "ArrowFunctionExpression";

walk(program, { scopeTracker: scopes });
scopes.freeze();

walk(program, {
  scopeTracker: scopes,
  enter(node, parent) {
    if (functionNode(node)) functionStack.push(node);

    if (!isReferenceIdentifier(node, parent)) return;

    const declaration = scopes.getDeclaration(node.name);

    if (
      declaration?.constructor?.name === "ScopeTrackerFunctionParam" &&
      declaration.fnNode === functionStack.at(-1)
    ) {
      parameterReferences.push({ name: node.name, start: node.start, end: node.end });
    }
  },
  leave(node) {
    if (functionNode(node)) functionStack.pop();
  },
});

convert(program);

for (const reference of parameterReferences) {
  reference.start = toBytes[reference.start];
  reference.end = toBytes[reference.end];
}

process.stdout.write(JSON.stringify({ program, module, analysis: { parameterReferences } }));
