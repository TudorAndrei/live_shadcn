// AI Elements does not publish a standalone Toolbar example. This narrow
// fixture uses the pinned Toolbar class contract without a live graph store.
export default function ToolbarDefault() {
  return (
    <div className="flex items-center gap-1 rounded-sm border bg-background p-1.5 w-fit">
      <button className="text-xs" type="button" aria-label="Run">Run</button>
    </div>
  );
}
