import assert from "node:assert/strict";
import test from "node:test";
import { exampleExport } from "../example-export.mjs";

test("code samples inside template strings cannot select an example export", () => {
  const source = [
    "const code = `export function Chat() { return <MessageList /> }`",
    "export function CodeBlockTabs() { return <pre>{code}</pre> }",
  ].join("\n");
  assert.equal(exampleExport(source, "code-block-tabs.tsx"), "CodeBlockTabs");
});

test("default example functions remain valid beside code sample exports", () => {
  const source = [
    "const code = `export function Example() {}`",
    "export default function Demo() { return <pre>{code}</pre> }",
  ].join("\n");
  assert.equal(exampleExport(source, "demo.tsx"), "default");
});
