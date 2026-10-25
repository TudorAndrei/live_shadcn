defmodule LiveBase.Menubar do
  @moduledoc """
  The client behavior for the top-level items in a menubar.

  The popup menus use `LiveBase.Menu`. This hook only moves between the
  top-level triggers and moves an open menu when the pointer crosses the bar.
  """

  use Phoenix.Component

  @hook "LiveBase.Menubar.Menubar"

  @doc "The client hook name for a menubar root."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook menubar.js#Menubar --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Menubar">
      const NEXT = "ArrowRight";
      const PREVIOUS = "ArrowLeft";
      const SWITCH_DELAY = 100;
      const Menubar = {
        mounted() {
          this.keydown = (event) => this.onKeydown(event);
          this.pointermove = (event) => this.onPointerMove(event);
          this.pointerleave = () => this.cancelSwitch();
          this.el.addEventListener("keydown", this.keydown);
          this.el.addEventListener("pointermove", this.pointermove);
          this.el.addEventListener("pointerleave", this.pointerleave);
        },
        destroyed() {
          this.cancelSwitch();
          this.el.removeEventListener("keydown", this.keydown);
          this.el.removeEventListener("pointermove", this.pointermove);
          this.el.removeEventListener("pointerleave", this.pointerleave);
        },
        triggers() {
          return [...this.el.querySelectorAll("[data-slot='menubar-trigger']")].filter((trigger) => trigger.closest("[data-slot='menubar']") === this.el && !trigger.hasAttribute("data-disabled") && !trigger.disabled && trigger.offsetParent);
        },
        onKeydown(event) {
          const triggers = this.triggers();
          const from = triggers.indexOf(document.activeElement);
          if (from === -1) return;
          let to = null;
          if (event.key === NEXT) to = (from + 1) % triggers.length;
          if (event.key === PREVIOUS) to = (from - 1 + triggers.length) % triggers.length;
          if (event.key === "Home") to = 0;
          if (event.key === "End") to = triggers.length - 1;
          if (to === null) return;
          event.preventDefault();
          triggers[to].focus();
        },
        onPointerMove(event) {
          const target = event.target.closest("[data-slot='menubar-trigger']");
          if (!target || target.closest("[data-slot='menubar']") !== this.el) return;
          const open = this.triggers().find((trigger) => trigger.getAttribute("aria-expanded") === "true");
          if (!open || open === target || target.disabled) return;
          this.cancelSwitch();
          this.switchTimer = setTimeout(() => {
            if (!target.matches(":hover") || !target.offsetParent) return;
            open.click();
            target.click();
          }, SWITCH_DELAY);
        },
        cancelSwitch() {
          clearTimeout(this.switchTimer);
          this.switchTimer = null;
        }
      };
      export default Menubar;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
