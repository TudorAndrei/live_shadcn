import { Spinner } from "@upstream/shadcn/ui/spinner";

// Ported from `StorybookWeb.Examples.spinner_default/1`.
export default function SpinnerDefault() {
  return (
    <div className="flex items-center gap-2 text-sm">
      <Spinner />
      <span>Verifying</span>
    </div>
  );
}
