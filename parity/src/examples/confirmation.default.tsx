import { Confirmation } from "@upstream/ai_elements/confirmation";

// Ported from `StorybookWeb.Examples.confirmation_default/1`.
//
// `approval` and `state` are what upstream draws *anything* at all for: with no
// approval, or with a tool call still streaming, `Confirmation` returns null.
// The reviewed port keeps that guard — `if (…) return null` at the top of
// a render is a fact about the whole part — so both sides are asked for the
// state the component is about.
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
