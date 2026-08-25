import { Confirmation } from "@upstream/ai_elements/confirmation";

// Ported from `StorybookWeb.Examples.confirmation_default/1`.
//
// `approval` and `state` are what upstream draws *anything* at all for: with no
// approval, or with a tool call still streaming, `Confirmation` returns null.
// The generated component takes both as attributes and draws the alert whatever
// they say, because a component that renders nothing is a decision the caller
// makes with `:if`. So the reference asks for the state the page is in.
export default function ConfirmationDefault() {
  return (
    <Confirmation
      className="max-w-md"
      approval={{ approved: false, id: "branch" }}
      state="approval-requested"
    >
      Delete the branch?
    </Confirmation>
  );
}
