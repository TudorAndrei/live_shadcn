defmodule LiveBase.Resizable do
  @moduledoc "The browser behavior behind a pointer-resizable panel group."

  use Phoenix.Component

  @hook "LiveBase.Resizable.Resizable"

  @doc "The client hook name the group declares."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook resizable.js#Resizable --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Resizable">
      const Resizable = {
        mounted() {
          this.onPointerDown = (event) => this.drag(event);
          this.el.addEventListener("pointerdown", this.onPointerDown);
        },
        destroyed() {
          this.el.removeEventListener("pointerdown", this.onPointerDown);
        },
        drag(event) {
          const handle = event.target.closest("[data-lb-resizable-handle]");
          if (!handle) return;
          if (handle.closest("[data-lb-orientation]") !== this.el) return;
          const previous = handle.previousElementSibling;
          const next = handle.nextElementSibling;
          if (!previous || !next) return;
          event.preventDefault();
          handle.setPointerCapture(event.pointerId);
          const horizontal = this.el.dataset.lbOrientation !== "vertical";
          const start = horizontal ? event.clientX : event.clientY;
          const previousSize = horizontal ? previous.getBoundingClientRect().width : previous.getBoundingClientRect().height;
          const nextSize = horizontal ? next.getBoundingClientRect().width : next.getBoundingClientRect().height;
          const move = (pointer) => {
            const delta = (horizontal ? pointer.clientX : pointer.clientY) - start;
            const before = Math.max(0, previousSize + delta);
            const after = Math.max(0, nextSize - delta);
            previous.style.setProperty("--lb-resizable-size", `${before}px`);
            previous.style.flexBasis = "var(--lb-resizable-size)";
            next.style.setProperty("--lb-resizable-size", `${after}px`);
            next.style.flexBasis = "var(--lb-resizable-size)";
          };
          const release = () => {
            handle.removeEventListener("pointermove", move);
            handle.removeEventListener("pointerup", release);
            handle.removeEventListener("pointercancel", release);
          };
          handle.addEventListener("pointermove", move);
          handle.addEventListener("pointerup", release);
          handle.addEventListener("pointercancel", release);
        }
      };
      export default Resizable;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
