import {
  PromptInput,
  PromptInputBody,
  PromptInputFooter,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputTools,
} from "@upstream/ai_elements/prompt-input";

// Ported from `StorybookWeb.Examples.prompt_input_default/1`.
//
// Twenty-two of upstream's thirty-five parts wrap a dropdown menu, a select, a
// hover card or a command palette part by part. Each of those components is one
// function in the port — its parts have to agree about one id — so there is
// nothing for the wrappers to wrap, and the `@moduledoc` names the four to
// compose instead. These are the parts that are the prompt input's own.
export default function PromptInputDefault() {
  return (
    <PromptInput className="max-w-md" onSubmit={() => undefined}>
      <PromptInputBody>
        <PromptInputTextarea placeholder="What would you like to know?" />
        <PromptInputFooter>
          <PromptInputTools />
          <PromptInputSubmit />
        </PromptInputFooter>
      </PromptInputBody>
    </PromptInput>
  );
}
