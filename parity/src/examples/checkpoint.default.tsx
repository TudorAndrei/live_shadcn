import {
  Checkpoint,
  CheckpointIcon,
  CheckpointTrigger,
} from "@upstream/ai_elements/checkpoint";

// Ported from `StorybookWeb.Examples.checkpoint_default/1`.
//
// The label is the trigger, which is a button: it brings the `whitespace-nowrap`
// that keeps the label on one line and leaves the separator the rest of the row.
export default function CheckpointDefault() {
  return (
    <Checkpoint className="max-w-md">
      <CheckpointTrigger>
        <CheckpointIcon /> Reverted to the spec before the fold
      </CheckpointTrigger>
    </Checkpoint>
  );
}
