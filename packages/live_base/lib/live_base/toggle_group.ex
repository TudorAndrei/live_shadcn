defmodule LiveBase.ToggleGroup do
  @moduledoc """
  Changes the pressed items of a toggle group without a server round trip.
  An item asks for a change with a `live-base:toggle-group` event.
  """

  use Phoenix.Component

  @doc "The client hook name the group declares in `phx-hook`."
  def hook, do: "LiveBase.ToggleGroup.ToggleGroup"

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook toggle_group.js#ToggleGroup --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ToggleGroup">
      const ToggleGroup = {
        mounted() {
          this.el.addEventListener("live-base:toggle-group", (event) => this.toggle(event));
        },
        toggle(event) {
          const item = document.getElementById(event.detail.item);
          if (!item || item.disabled || item.getAttribute("aria-disabled") === "true") return;
          const wasPressed = item.getAttribute("aria-pressed") === "true";
          if (this.el.hasAttribute("data-multiple")) this.setPressed(item, !wasPressed);
          else {
            for (const other of this.items()) this.setPressed(other, false);
            if (!wasPressed) this.setPressed(item, true);
          }
          item.setAttribute("data-dirty", "");
          item.setAttribute("data-touched", "");
          this.updateOutput(item, !wasPressed);
        },
        items() {
          return [...this.el.querySelectorAll("[data-slot='toggle-group-item']")].filter((item) => item.closest("[data-slot='toggle-group']") === this.el);
        },
        setPressed(item, pressed) {
          item.setAttribute("aria-pressed", String(pressed));
          item.toggleAttribute("data-pressed", pressed);
        },
        updateOutput(item, selected) {
          const selector = this.el.getAttribute("data-lb-output");
          if (!selector) return;
          const output = document.querySelector(selector);
          if (output) {
            const prefix = this.el.getAttribute("data-lb-output-prefix") || "";
            output.replaceChildren(document.createTextNode(prefix), document.createTextNode(selected ? item.getAttribute("data-lb-value") || "" : ""));
          }
        }
      };
      export default ToggleGroup;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
