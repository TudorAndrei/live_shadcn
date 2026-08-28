// AI Elements does not publish a standalone Controls example. This narrow
// fixture uses the pinned Controls class contract without a live graph store.
export default function ControlsDefault() {
  return (
    <div className="gap-px overflow-hidden rounded-md border bg-card p-1 shadow-none! [&>button]:rounded-md [&>button]:border-none! [&>button]:bg-transparent! [&>button]:hover:bg-secondary! w-fit">
      <button type="button" className="p-1" aria-label="Zoom in">+</button>
      <button type="button" className="p-1" aria-label="Zoom out">-</button>
    </div>
  );
}
