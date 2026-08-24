import {
  Progress,
  ProgressIndicator,
  ProgressLabel,
  ProgressTrack,
  ProgressValue,
} from "@upstream/shadcn/ui/progress";

// Ported from `StorybookWeb.Examples.progress_default/1`.
export default function ProgressDefault() {
  return (
    <Progress value={62} className="max-w-sm">
      <ProgressLabel>Generating</ProgressLabel>
      <ProgressValue>62%</ProgressValue>
      <ProgressTrack>
        <ProgressIndicator />
      </ProgressTrack>
    </Progress>
  );
}
