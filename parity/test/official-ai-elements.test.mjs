import assert from "node:assert/strict";
import test from "node:test";

import { discovery, entries } from "../src/official-ai-elements.mjs";

test("discovers component examples and leaves application demos out", () => {
  const manifest = {
    files: {
      "ai_elements/audio-player.tsx": {},
      "ai_elements/tool.tsx": {},
      "ai_examples/audio-player-remote.tsx": {},
      "ai_examples/audio-player.tsx": {},
      "ai_examples/chatbot.tsx": {},
      "ai_examples/tool-input-available.tsx": {},
      "ai_examples/tool.tsx": {},
    },
  };

  const source = {
    "audio-player": 'import { AudioPlayer } from "@repo/elements/audio-player";',
    "audio-player-remote": 'import { AudioPlayer } from "@repo/elements/audio-player";',
    chatbot: 'import { Message } from "@repo/elements/message";',
    tool: 'import { Tool } from "@repo/elements/tool";',
    "tool-input-available": 'import { Tool } from "@repo/elements/tool";',
  };

  assert.deepEqual(entries(manifest, (name) => source[name]), [
    { component: "audio-player", id: "default", source: "audio-player" },
    { component: "audio-player", id: "remote", source: "audio-player-remote" },
    { component: "tool", id: "default", source: "tool" },
    { component: "tool", id: "input-available", source: "tool-input-available" },
  ]);
});

test("rejects an ambiguous filename prefix relationship", () => {
  const manifest = {
    files: {
      "ai_elements/tool.tsx": {},
      "ai_elements/tool-call.tsx": {},
      "ai_examples/tool-call-state.tsx": {},
    },
  };

  const source = () =>
    'import { Tool } from "@repo/elements/tool"; import { ToolCall } from "@repo/elements/tool-call";';

  assert.deepEqual(discovery(manifest, source).problems, [
    "tool-call-state: imports more than one filename candidate: tool, tool-call",
  ]);
});
