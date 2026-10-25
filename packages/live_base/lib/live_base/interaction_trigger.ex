defmodule LiveBase.InteractionTrigger do
  @moduledoc """
  Opens a popup from a gesture that is not a plain click: hover or focus for a
  tooltip or hover card, a right click for a context menu.

  The trigger's `phx-click` keeps the `JS` command that opens the popup. The
  hook only turns the gesture into that command.
  """

  use Phoenix.Component

  @doc "The client hook name the trigger declares in `phx-hook`."
  def hook, do: "LiveBase.InteractionTrigger.InteractionTrigger"

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook interaction_trigger.js#InteractionTrigger --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".InteractionTrigger">
      const InteractionTrigger = {
        mounted() {
          this.popupId = this.el.getAttribute("aria-controls");
          this.positioner = document.getElementById(this.el.dataset.lbPositioner);
          this.syncTrustedClickBlocker();
          if (this.el.hasAttribute("data-lb-open-on-hover")) this.mountHover();
          if (this.el.hasAttribute("data-lb-open-on-context")) this.mountContextMenu();
        },
        updated() {
          this.syncTrustedClickBlocker();
        },
        destroyed() {
          clearTimeout(this.openTimer);
          clearTimeout(this.closeTimer);
          if (this.blockTrustedClick) {
            this.el.removeEventListener("click", this.blockTrustedClick, true);
            this.blockTrustedClick = null;
          }
          for (const [element, event, listener, options] of this.listeners || []) element.removeEventListener(event, listener, options);
        },
        syncTrustedClickBlocker() {
          const callerOwnsClick = this.el.hasAttribute("data-lb-caller-click");
          if (!callerOwnsClick && !this.blockTrustedClick) {
            this.blockTrustedClick = (event) => {
              if (event.isTrusted) event.stopImmediatePropagation();
            };
            this.el.addEventListener("click", this.blockTrustedClick, true);
          }
          if (callerOwnsClick && this.blockTrustedClick) {
            this.el.removeEventListener("click", this.blockTrustedClick, true);
            this.blockTrustedClick = null;
          }
        },
        mountHover() {
          this.pointerPressed = false;
          this.on(this.el, "pointerenter", () => this.schedulePointerOpen());
          this.on(this.el, "pointerdown", () => this.markPointerPressed());
          this.on(this.el, "pointerleave", () => this.leavePointer());
          this.on(this.el, "focusin", () => this.scheduleFocusOpen());
          this.on(this.el, "focusout", () => this.scheduleClose());
          this.on(document, "pointermove", (event) => {
            const popup = this.popupElement();
            if (this.el.contains(event.target) || popup?.contains(event.target)) clearTimeout(this.closeTimer);
            else if (this.el.hasAttribute("data-popup-open")) this.scheduleClose();
          });
        },
        schedulePointerOpen() {
          if (!this.pointerPressed) this.scheduleOpen();
        },
        markPointerPressed() {
          this.pointerPressed = true;
          if (this.el.hasAttribute("data-lb-hover-card") || this.el.getAttribute("data-slot") === "hover-card-trigger") return;
          clearTimeout(this.openTimer);
          if (this.el.hasAttribute("data-popup-open")) {
            this.executeHoverCommand();
            this.clearHoverExpanded();
          }
        },
        leavePointer() {
          this.pointerPressed = false;
          this.scheduleClose();
        },
        scheduleFocusOpen() {
          if (!this.pointerPressed) this.scheduleOpen();
        },
        mountContextMenu() {
          this.on(this.el, "contextmenu", (event) => {
            event.preventDefault();
            this.positioner?.setAttribute("data-lb-point-x", String(event.clientX));
            this.positioner?.setAttribute("data-lb-point-y", String(event.clientY));
            if (this.el.hasAttribute("data-popup-open")) this.positioner?.dispatchEvent(new CustomEvent("live-base:reposition"));
            else this.openClick();
          });
        },
        openHover() {
          clearTimeout(this.openTimer);
          clearTimeout(this.closeTimer);
          if (!this.el.hasAttribute("data-popup-open")) this.executeHoverCommand();
          this.clearHoverExpanded();
        },
        openClick() {
          clearTimeout(this.openTimer);
          clearTimeout(this.closeTimer);
          if (!this.el.hasAttribute("data-popup-open")) this.executeClickCommand();
          this.el.removeAttribute("aria-expanded");
        },
        scheduleClose() {
          clearTimeout(this.openTimer);
          clearTimeout(this.closeTimer);
          this.closeTimer = setTimeout(() => {
            if (this.el.matches(":hover, :focus-within") || this.popupElement()?.matches(":hover, :focus-within")) return;
            if (this.el.hasAttribute("data-popup-open")) this.executeHoverCommand();
            this.clearHoverExpanded();
          }, this.delay("lbCloseDelay", 80));
        },
        scheduleOpen() {
          clearTimeout(this.openTimer);
          clearTimeout(this.closeTimer);
          const delay = this.delay("lbOpenDelay", 0);
          this.openTimer = setTimeout(() => this.openHover(), delay);
        },
        delay(name, fallback) {
          const value = Number(this.el.dataset[name]);
          return Number.isFinite(value) && value >= 0 ? value : fallback;
        },
        popupElement() {
          return this.popupId ? document.getElementById(this.popupId) : null;
        },
        executeClickCommand() {
          const command = this.el.getAttribute("phx-click");
          if (command) this.liveSocket.execJS(this.el, command);
        },
        executeHoverCommand() {
          const command = this.el.getAttribute("data-lb-hover-command") || this.el.getAttribute("phx-click");
          if (command) this.liveSocket.execJS(this.el, command);
        },
        clearHoverExpanded() {
          requestAnimationFrame(() => this.el.removeAttribute("aria-expanded"));
        },
        on(element, event, listener, options) {
          this.listeners ||= [];
          this.listeners.push([
            element,
            event,
            listener,
            options
          ]);
          element.addEventListener(event, listener, options);
        }
      };
      export default InteractionTrigger;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
