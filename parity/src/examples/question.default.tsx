import {
  Question,
  QuestionActions,
  QuestionDescription,
  QuestionInput,
  QuestionOption,
  QuestionOptions,
  QuestionPrompt,
  QuestionSubmit,
} from "@upstream/ai_elements/question";

// Ported from `StorybookWeb.Examples.question_default/1`.
//
// Upstream keeps which option is chosen in a React context and the generated
// component takes it as an attribute per option, because the server owns a
// value a form submits. So the reference is given the same answer as chosen —
// `defaultValue` — and both sides draw the first option selected.
export default function QuestionDefault() {
  return (
    <Question
      className="max-w-md"
      defaultValue={{ selectedValues: ["disclosure"], text: "" }}
      selectionMode="single"
    >
      <QuestionPrompt>Which recipe should read this component?</QuestionPrompt>
      <QuestionDescription>
        Pick one. The box below takes anything the list does not cover.
      </QuestionDescription>
      <QuestionOptions>
        <QuestionOption value="disclosure">Disclosure</QuestionOption>
        <QuestionOption value="popover">Popover</QuestionOption>
        <QuestionOption value="listbox">Listbox</QuestionOption>
      </QuestionOptions>
      <QuestionInput aria-label="Something else" name="other" placeholder="Something else" />
      <QuestionActions>
        <QuestionSubmit size="sm">Answer</QuestionSubmit>
      </QuestionActions>
    </Question>
  );
}
