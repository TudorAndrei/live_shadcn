import {
  Questionnaire,
  QuestionnaireChoice,
  QuestionnaireChoiceDescription,
  QuestionnaireChoices,
  QuestionnaireDescription,
  QuestionnaireItem,
  QuestionnaireProgress,
  QuestionnaireTitle,
} from "@upstream/shadcn/ui/questionnaire";

// Ported from `StorybookWeb.Examples.questionnaire_default/1`.
export default function QuestionnaireDefault() {
  return (
    <Questionnaire>
      <QuestionnaireProgress>1 of 2</QuestionnaireProgress>
      <QuestionnaireItem>
        <QuestionnaireTitle>How should the server filter commands?</QuestionnaireTitle>
        <QuestionnaireDescription>Choose one behaviour for each keystroke.</QuestionnaireDescription>
        <QuestionnaireChoices className="mt-4 gap-2">
          <QuestionnaireChoice>
            On the server
            <QuestionnaireChoiceDescription>One round trip per keystroke.</QuestionnaireChoiceDescription>
          </QuestionnaireChoice>
          <QuestionnaireChoice>
            In the browser
            <QuestionnaireChoiceDescription>Keep a second copy of the list.</QuestionnaireChoiceDescription>
          </QuestionnaireChoice>
        </QuestionnaireChoices>
      </QuestionnaireItem>
    </Questionnaire>
  );
}
