defmodule LiveBase.Toast do
  @moduledoc """
  The behavior behind a stack of messages the reader did not ask for.

  ## Who owns the list

  The server, and that is the whole design. React's toast is a manager object
  the client holds: `toast.add(…)` from anywhere, and the component reads it.
  A LiveView already has somewhere to keep a list of things, and a toast that
  the client held would disagree with it the moment the server re-rendered —
  the reader would watch a dismissed message come back.

  So the caller keeps the toasts in an assign or a stream, the component draws
  what is there, and dismissing one is an event like any other:

      def handle_event("dismiss_toast", %{"id" => id}, socket) do
        {:noreply, update(socket, :toasts, &Enum.reject(&1, fn t -> t.id == id end))}
      end

  ## What the hook owns

  Everything about the stack that only a browser knows: how tall each toast
  turned out, how far back it sits, how far a finger has pushed it. Those are
  six CSS variables and three data attributes, and shadcn's class strings read
  every one of them to place the stack, fan it out under a pointer, and slide a
  pushed toast away.

  | Variable | What it holds |
  |---|---|
  | `--toast-index` | how far back this one is, 0 at the front |
  | `--toast-height` | how tall it is, measured |
  | `--toast-frontmost-height` | how tall the front one is |
  | `--toast-offset-y` | how far down the stack this one starts |
  | `--toast-swipe-movement-x` | how far a finger has pushed it |
  | `--toast-swipe-movement-y` | the same, down |

  ## Timing out is still an event

  A toast that stays for four seconds asks the server to remove it after four
  seconds. One round trip per toast, which is one more than none and far fewer
  than a component that asked what to draw.
  """

  use Phoenix.Component

  @hook "LiveBase.Toast.Toast"

  @doc "The client hook name the viewport declares in `phx-hook`."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook toast.js#Toast --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Toast">
      const THRESHOLD = 48;
      const Toast = {
        mounted() {
          this.timers = new Map();
          this.focused = false;
          this.hovered = false;
          this.focusHandlers = new Map();
          this.onToastFocus = () => {
            if (document.activeElement?.matches(":focus-visible")) this.focused = true;
            this.expand(this.focused || this.hovered);
          };
          this.listeners = {
            pointerenter: () => {
              this.hovered = true;
              this.expand(true);
            },
            pointerleave: () => {
              this.hovered = false;
              this.expand(this.focused);
            },
            focusin: (event) => {
              if (this.focusHandlers.get(event.target)?.handler !== event.target.onfocus) this.onToastFocus();
            },
            focusout: (event) => {
              if (this.el.contains(event.relatedTarget)) return;
              this.focused = false;
              this.expand(this.hovered);
            }
          };
          for (const [name, handler] of Object.entries(this.listeners)) this.el.addEventListener(name, handler);
          this.arrange();
        },
        updated() {
          this.arrange();
        },
        destroyed() {
          for (const [name, handler] of Object.entries(this.listeners)) this.el.removeEventListener(name, handler);
          for (const timer of this.timers.values()) clearTimeout(timer);
          for (const target of this.focusHandlers.keys()) this.releaseFocusHandler(target);
        },
        releaseFocusHandler(target) {
          const { handler, previous } = this.focusHandlers.get(target);
          if (target.onfocus === handler) target.onfocus = previous;
          this.focusHandlers.delete(target);
        },
        bindFocusHandlers() {
          for (const target of this.focusHandlers.keys()) if (!this.el.contains(target)) this.releaseFocusHandler(target);
          for (const target of this.el.querySelectorAll("[data-slot='toast'], [data-slot='toast-action'], [data-slot='toast-close']")) {
            if (this.focusHandlers.has(target)) continue;
            const previous = target.onfocus;
            const handler = (event) => {
              previous?.call(target, event);
              this.onToastFocus();
            };
            this.focusHandlers.set(target, {
              previous,
              handler
            });
            target.onfocus = handler;
          }
        },
        toasts() {
          return [...this.el.querySelectorAll("[data-slot='toast'], [data-sonner-toast]")];
        },
        arrange() {
          const toasts = this.toasts();
          const front = toasts[0];
          if (front) this.el.style.setProperty("--toast-frontmost-height", `${front.offsetHeight}px`);
          let offset = 0;
          const limit = Number(this.el.getAttribute("data-lb-limit") || 0);
          toasts.forEach((toast, index) => {
            if (!toast.style.getPropertyValue("--toast-swipe-movement-x")) toast.style.setProperty("--toast-swipe-movement-x", "0px");
            if (!toast.style.getPropertyValue("--toast-swipe-movement-y")) toast.style.setProperty("--toast-swipe-movement-y", "0px");
            toast.style.setProperty("--toast-index", index);
            toast.style.setProperty("--toast-height", `${toast.offsetHeight}px`);
            toast.style.setProperty("--toast-offset-y", `${offset}px`);
            offset += toast.offsetHeight;
            this.mark(toast, "data-behind", index > 0);
            this.mark(toast, "data-limited", limit > 0 && index >= limit);
            this.arm(toast);
            this.grabbable(toast);
          });
          this.bindFocusHandlers();
          this.expand(this.focused || this.hovered);
        },
        mark(toast, attribute, on) {
          toast.toggleAttribute(attribute, on);
          for (const target of toast.querySelectorAll("[data-lb-style-target]")) target.toggleAttribute(attribute, on);
        },
        arm(toast) {
          const id = toast.id;
          const duration = Number(this.el.getAttribute("data-lb-duration") || 0);
          if (!id || duration <= 0 || this.timers.has(id)) return;
          this.timers.set(id, setTimeout(() => {
            this.timers.delete(id);
            this.dismiss(toast);
          }, duration));
        },
        dismiss(toast, direction) {
          const event = this.el.getAttribute("data-lb-dismiss");
          if (!event || !toast.id) return;
          if (direction) toast.setAttribute("data-swipe-direction", direction);
          this.pushEvent(event, { id: toast.id });
        },
        targets() {
          return [this.el, ...this.el.querySelectorAll("[data-lb-style-target]")];
        },
        expand(on) {
          for (const target of this.targets()) target.toggleAttribute("data-expanded", on);
          for (const toast of this.el.querySelectorAll("[data-slot='toast']")) {
            if (toast.getAttribute("role") === "alertdialog") {
              if (this.focused) toast.removeAttribute("aria-hidden");
              else toast.setAttribute("aria-hidden", "true");
            }
            for (const close of toast.querySelectorAll("[data-slot='toast-close']")) close.setAttribute("aria-hidden", String(!on && close !== document.activeElement));
          }
          for (const announcement of this.el.parentElement.querySelectorAll("[data-lb-toast-announcement]")) announcement.hidden = this.focused;
        },
        grabbable(toast) {
          if (toast.dataset.lbGrabbable) return;
          toast.dataset.lbGrabbable = "true";
          toast.addEventListener("pointerdown", (event) => this.grab(event, toast));
        },
        grab(event, toast) {
          if (event.target.closest("button, a, [role='button']")) return;
          toast.setPointerCapture(event.pointerId);
          toast.toggleAttribute("data-swiping", true);
          const from = {
            x: event.clientX,
            y: event.clientY
          };
          const move = (moved) => {
            const x = moved.clientX - from.x;
            const y = Math.max(0, moved.clientY - from.y);
            toast.style.setProperty("--toast-swipe-movement-x", `${x}px`);
            toast.style.setProperty("--toast-swipe-movement-y", `${y}px`);
          };
          const release = (released) => {
            toast.removeEventListener("pointermove", move);
            toast.removeEventListener("pointerup", release);
            toast.removeEventListener("pointercancel", release);
            toast.removeAttribute("data-swiping");
            const x = released.clientX - from.x;
            const y = released.clientY - from.y;
            if (Math.abs(x) > THRESHOLD) return this.dismiss(toast, x > 0 ? "right" : "left");
            if (y > THRESHOLD) return this.dismiss(toast, "down");
            toast.style.removeProperty("--toast-swipe-movement-x");
            toast.style.removeProperty("--toast-swipe-movement-y");
          };
          toast.addEventListener("pointermove", move);
          toast.addEventListener("pointerup", release);
          toast.addEventListener("pointercancel", release);
        }
      };
      export default Toast;
    </script>
    <%!-- /colocated-hook --%>
    """
  end

  @doc "The id of one toast, given the toaster and the toast's own id."
  def toast_id(toaster, id), do: "#{toaster}-#{id}"
end
