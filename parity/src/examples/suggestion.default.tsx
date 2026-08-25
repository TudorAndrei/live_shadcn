import { Suggestion, Suggestions } from "@upstream/ai_elements/suggestion";

// Ported from `StorybookWeb.Examples.suggestion_default/1`.
//
// `suggestion` is both the text and what the click reports upstream. The
// generated component takes the text as content, because a click is
// `phx-click` and the caller writes what it carries.
export default function SuggestionDefault() {
  return (
    <Suggestions className="max-w-md">
      <Suggestion suggestion="What does mix ui.spec read?" />
      <Suggestion suggestion="Why four hooks?" />
      <Suggestion suggestion="Show me the accordion" />
    </Suggestions>
  );
}
