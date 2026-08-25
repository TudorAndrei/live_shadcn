import {
  EnvironmentVariable,
  EnvironmentVariableCopyButton,
  EnvironmentVariableGroup,
  EnvironmentVariableName,
  EnvironmentVariableRequired,
  EnvironmentVariableValue,
  EnvironmentVariables,
  EnvironmentVariablesContent,
  EnvironmentVariablesHeader,
  EnvironmentVariablesTitle,
  EnvironmentVariablesToggle,
} from "@upstream/ai_elements/environment-variables";

// Ported from `StorybookWeb.Examples.environment_variables_default/1`.
//
// The page is drawn with the values hidden, which is where the storybook starts
// and — on that side — the only state in which the secret is not in the page at
// all. Upstream keeps `showValues` in a React context; the generated component
// takes it as an attribute, because the server decides when the page is given a
// secret.
export default function EnvironmentVariablesDefault() {
  return (
    <EnvironmentVariables className="max-w-md">
      <EnvironmentVariablesHeader>
        <EnvironmentVariablesTitle />
        <EnvironmentVariablesToggle />
      </EnvironmentVariablesHeader>
      <EnvironmentVariablesContent>
        <EnvironmentVariable name="MIX_ENV" value="prod">
          <EnvironmentVariableGroup>
            <EnvironmentVariableName />
            <EnvironmentVariableRequired />
          </EnvironmentVariableGroup>
          <EnvironmentVariableGroup>
            <EnvironmentVariableValue />
            <EnvironmentVariableCopyButton aria-label="Copy MIX_ENV" />
          </EnvironmentVariableGroup>
        </EnvironmentVariable>
        <EnvironmentVariable name="SECRET_KEY_BASE" value="sup3rs3cr3t">
          <EnvironmentVariableGroup>
            <EnvironmentVariableName />
          </EnvironmentVariableGroup>
          <EnvironmentVariableGroup>
            <EnvironmentVariableValue />
            <EnvironmentVariableCopyButton aria-label="Copy SECRET_KEY_BASE" />
          </EnvironmentVariableGroup>
        </EnvironmentVariable>
      </EnvironmentVariablesContent>
    </EnvironmentVariables>
  );
}
