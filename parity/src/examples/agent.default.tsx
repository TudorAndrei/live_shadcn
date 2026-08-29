import {
  Agent,
  AgentContent,
  AgentHeader,
  AgentInstructions,
} from "@upstream/ai_elements/agent";

// The same input as `StorybookWeb.Examples.agent_default/1`, rendered by the
// pinned official React component.
export default function AgentDefault() {
  return (
    <Agent className="max-w-md">
      <AgentHeader model="claude-opus-4.5" name="Reader" />
      <AgentContent>
        <AgentInstructions>
          Read every registry source and write one spec for each.
        </AgentInstructions>
      </AgentContent>
    </Agent>
  );
}
