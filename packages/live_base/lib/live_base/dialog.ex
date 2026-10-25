defmodule LiveBase.Dialog do
  @moduledoc """
  The behavior behind anything that opens over the page and takes the focus
  with it: dialog, alert dialog, sheet, drawer.

  ## What the recipe owns

  A dialog is one open state and four consequences of it. The state is a
  `Phoenix.LiveView.JS` command; the consequences are not all expressible as
  one:

  | Consequence | Where it lives |
  |---|---|
  | the attributes a class string reads | a `JS` command |
  | where the focus goes, and where it comes back to | a `JS` command |
  | the focus staying inside while it is open | the client hook |
  | the page behind not scrolling | the client hook |
  | the enter and exit transitions | the client hook |

  ## The attribute contract

  | Element | Attribute | When |
  |---|---|---|
  | trigger | `data-popup-open` | present while open |
  | backdrop, popup | `data-open` | present while open |
  | backdrop, popup | `data-closed` | present while closed |
  | backdrop, popup | `data-starting-style` | while animating in |
  | backdrop, popup | `data-ending-style` | while animating out |

  ## Identifiers

  Every id is derived from the dialog's own, the same way a disclosure derives
  an item's:

      "confirm"              the dialog
      "confirm-trigger"      the button that opens it
      "confirm-backdrop"     the layer behind it
      "confirm-popup"        the dialog itself
      "confirm-title"        what names it
      "confirm-description"  what describes it

  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Dialog.Overlay"

  @doc "The client hook name the popup declares in `phx-hook`."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook overlay.js#Overlay --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Overlay">
      const STARTING = "data-starting-style";
      const ENDING = "data-ending-style";
      function show(layers, animate = true) {
        for (const layer of layers) {
          layer.removeAttribute(ENDING);
          layer.hidden = false;
        }
        if (!animate) return;
        mark(layers, STARTING);
        layers[0].offsetHeight;
        unmark(layers, STARTING);
      }
      function hide(layers) {
        mark(layers, ENDING);
        return setTimeout(() => {
          unmark(layers, ENDING);
          for (const layer of layers) layer.hidden = true;
        }, duration(layers[0]));
      }
      function mark(layers, attribute) {
        for (const layer of layers) layer.setAttribute(attribute, "");
      }
      function unmark(layers, attribute) {
        for (const layer of layers) layer.removeAttribute(attribute);
      }
      function duration(element) {
        const style = getComputedStyle(element);
        const times = [
          style.transitionDuration,
          style.transitionDelay,
          style.animationDuration
        ];
        return Math.max(...times.map(seconds)) * 1e3;
      }
      function seconds(list) {
        return Math.max(0, ...String(list).split(",").map((value) => parseFloat(value) || 0));
      }
      const accessibilityDocuments = globalThis[Symbol.for("live_base.modal_accessibility")] ??= new WeakMap();
      function accessibilityInside(popup) {
        const document = popup.ownerDocument;
        const inside = new Set([popup]);
        const candidates = [...document.querySelectorAll("[data-lb-anchor][data-open], [data-lb-trigger][data-open], [data-phx-teleported-src]")];
        let changed;
        do {
          changed = false;
          for (const node of candidates) {
            if (inside.has(node)) continue;
            const anchor = document.getElementById(node.getAttribute("data-lb-anchor") || node.getAttribute("data-lb-trigger"));
            const source = document.getElementById(node.getAttribute("data-phx-teleported-src"));
            if ([...inside].some((target) => anchor && target.contains(anchor) || source && target.contains(source) && node.querySelector("[data-open]"))) {
              inside.add(node);
              changed = true;
            }
          }
        } while (changed);
        return inside;
      }
      function outsideNodes(document, allowed) {
        const ancestors = new Set();
        for (const target of allowed) for (let node = target; node; node = node.parentElement) ancestors.add(node);
        const outside = new Set();
        const collect = (parent) => {
          for (const node of parent.children) {
            if (node.matches("script, template") || allowed.has(node)) continue;
            if (ancestors.has(node) || document.defaultView.getComputedStyle(node).display === "contents") collect(node);
            else outside.add(node);
          }
        };
        collect(document.body);
        return outside;
      }
      function refreshAccessibility(state, records = []) {
        const pending = [...records, ...state.observer.takeRecords()];
        for (const record of pending) if (record.attributeName === "aria-hidden" && state.hidden.has(record.target)) state.hidden.set(record.target, record.target.getAttribute("aria-hidden"));
        state.observer.disconnect();
        const front = state.owners.findLast((owner) => owner.element.isConnected && owner.element.hasAttribute("data-open"));
        const inside = front ? front.inside() : new Set();
        const allowed = new Set([...inside, ...state.document.querySelectorAll("[aria-live]")]);
        const outside = front ? outsideNodes(state.document, allowed) : new Set();
        for (const [node, value] of state.hidden) {
          if (outside.has(node)) continue;
          if (value === null) node.removeAttribute("aria-hidden");
          else node.setAttribute("aria-hidden", value);
          state.hidden.delete(node);
        }
        for (const node of outside) {
          if (!state.hidden.has(node)) state.hidden.set(node, node.getAttribute("aria-hidden"));
          if (node.getAttribute("aria-hidden") !== "true") node.setAttribute("aria-hidden", "true");
        }
        if (state.owners.length) state.observer.observe(state.document.body, {
          subtree: true,
          childList: true,
          attributes: true,
          attributeFilter: [
            "aria-hidden",
            "aria-live",
            "data-open",
            "hidden",
            "class",
            "style"
          ]
        });
      }
      function holdAccessibility(element, inside = () => accessibilityInside(element)) {
        const document = element.ownerDocument;
        let state = accessibilityDocuments.get(document);
        if (!state) {
          state = {
            document,
            owners: [],
            hidden: new Map()
          };
          state.observer = new document.defaultView.MutationObserver((records) => refreshAccessibility(state, records));
          accessibilityDocuments.set(document, state);
        }
        const lease = {
          element,
          inside,
          state,
          released: false
        };
        state.owners.push(lease);
        refreshAccessibility(state);
        return lease;
      }
      function releaseAccessibility(lease) {
        if (!lease || lease.released) return;
        lease.released = true;
        const state = lease.state;
        state.owners = state.owners.filter((owner) => owner !== lease);
        refreshAccessibility(state);
        if (state.owners.length) return;
        state.observer.disconnect();
        accessibilityDocuments.delete(state.document);
      }
      const OPEN = "data-open";
      const FOCUSABLE = [
        "a[href]",
        "button:not([disabled])",
        "input:not([disabled]):not([type='hidden'])",
        "select:not([disabled])",
        "textarea:not([disabled])",
        "[tabindex]:not([tabindex='-1'])"
      ].join(",");
      const modalDocuments = globalThis[Symbol.for("live_base.modal_stack")] ??= new WeakMap();
      function frontModal(state) {
        return state.owners.findLast((owner) => owner.el.isConnected && owner.el.hasAttribute(OPEN));
      }
      function refreshModal(state) {
        state.observer.disconnect();
        const front = frontModal(state);
        state.inside = front ? accessibilityInside(front.el) : new Set();
        if (state.owners.length) state.observer.observe(state.document.body, {
          subtree: true,
          childList: true,
          attributes: true,
          attributeFilter: [
            "aria-live",
            "data-open",
            "hidden",
            "class",
            "style"
          ]
        });
      }
      function holdModal(owner) {
        const document = owner.el.ownerDocument;
        let state = modalDocuments.get(document);
        if (!state) {
          state = {
            document,
            owners: [],
            inside: new Set(),
            overflow: document.body.style.overflow,
            padding: document.body.style.paddingRight
          };
          state.observer = new document.defaultView.MutationObserver(() => refreshModal(state));
          modalDocuments.set(document, state);
          const scrollbar = document.defaultView.innerWidth - document.documentElement.clientWidth;
          document.body.style.overflow = "hidden";
          if (scrollbar > 0) document.body.style.paddingRight = `${scrollbar}px`;
        }
        state.owners.push(owner);
        owner.accessibilityLease = holdAccessibility(owner.el);
        refreshModal(state);
        return state;
      }
      function releaseModal(owner, state) {
        releaseAccessibility(owner.accessibilityLease);
        owner.accessibilityLease = null;
        state.owners = state.owners.filter((candidate) => candidate !== owner);
        refreshModal(state);
        if (state.owners.length) return;
        state.document.body.style.overflow = state.overflow;
        state.document.body.style.paddingRight = state.padding;
        modalDocuments.delete(state.document);
      }
      const Overlay = {
        mounted() {
          this.modal = this.el.hasAttribute("data-lb-modal");
          this.open = this.el.hasAttribute(OPEN);
          this.onKeydown = (event) => this.keydown(event);
          this.onFocusIn = (event) => this.focusin(event);
          this.el.addEventListener("focusin", this.onFocusIn);
          if (this.open) this.enter(false);
          this.observer = new MutationObserver(() => this.stateChanged());
          this.observer.observe(this.el, {
            attributes: true,
            attributeFilter: [OPEN]
          });
        },
        destroyed() {
          this.observer?.disconnect();
          clearTimeout(this.timer);
          this.release();
          this.el.removeEventListener("focusin", this.onFocusIn);
        },
        layers() {
          const backdrop = this.el.getAttribute("data-lb-backdrop");
          const behind = backdrop && document.getElementById(backdrop);
          return behind ? [this.el, behind] : [this.el];
        },
        stateChanged() {
          const open = this.el.hasAttribute(OPEN);
          if (open === this.open) return;
          this.open = open;
          open ? this.enter(true) : this.leave();
        },
        enter(animate) {
          clearTimeout(this.timer);
          show(this.layers(), animate);
          this.hold();
        },
        leave() {
          clearTimeout(this.timer);
          this.release();
          this.timer = hide(this.layers());
        },
        hold() {
          if (!this.modal || this.held) return;
          this.held = holdModal(this);
          this.el.ownerDocument.addEventListener("keydown", this.onKeydown, true);
        },
        release() {
          if (!this.held) return;
          releaseModal(this, this.held);
          this.held = null;
          this.el.ownerDocument.removeEventListener("keydown", this.onKeydown, true);
        },
        focusin(event) {
          if (this.el.hasAttribute(OPEN)) return;
          const outside = event.relatedTarget;
          if (outside?.isConnected && !this.el.contains(outside) && !outside.closest("[hidden], [inert], [aria-hidden='true'], [role='dialog'][data-closed], [role='alertdialog'][data-closed]")) outside.focus({ preventScroll: true });
          if (this.el.contains(this.el.ownerDocument.activeElement)) event.target.blur();
        },
        keydown(event) {
          if (event.key !== "Tab" || event.defaultPrevented || frontModal(this.held) !== this) return;
          const focusable = [...new Set([...this.held.inside].flatMap((target) => [...target.querySelectorAll(FOCUSABLE)]))].filter((el) => el.tabIndex >= 0 && el.offsetParent && !el.closest("[aria-hidden='true'], [inert]"));
          if (focusable.length === 0) return event.preventDefault();
          const first = focusable[0];
          const last = focusable[focusable.length - 1];
          const active = this.el.ownerDocument.activeElement;
          if (![...this.held.inside].some((target) => target.contains(active))) {
            event.preventDefault();
            first.focus();
          } else if (event.shiftKey && active === first) {
            event.preventDefault();
            last.focus();
          } else if (!event.shiftKey && active === last) {
            event.preventDefault();
            first.focus();
          }
        }
      };
      export default Overlay;
    </script>
    <%!-- /colocated-hook --%>
    """
  end

  @doc "The id of the button that opens a dialog."
  def trigger_id(dialog), do: "#{dialog}-trigger"

  @doc "The id of the layer behind a dialog."
  def backdrop_id(dialog), do: "#{dialog}-backdrop"

  @doc "The id of the dialog itself."
  def popup_id(dialog), do: "#{dialog}-popup"

  @doc "The id of the heading that names a dialog."
  def title_id(dialog), do: "#{dialog}-title"

  @doc "The id of the text that describes a dialog."
  def description_id(dialog), do: "#{dialog}-description"

  @doc """
  Opens a dialog.

  `JS.push_focus` remembers where the reader was before the focus moves, so
  `close/2` can put it back. A dialog that opens from a button and closes to
  nowhere loses a keyboard reader's place on the page.

  Focus the popup before searching its children. If no child accepts focus,
  the popup keeps focus.
  """
  def open(js \\ %JS{}, dialog), do: open(js, dialog, :first)

  @doc """
  Opens a dialog with focus on its first focusable child or its popup.

  Use `:first` for ordinary dialogs and `:popup` for drawers. Both choices
  remember the previous focus and focus the popup before any child search.
  """
  def open(js, dialog, initial_focus) when initial_focus in [:first, :popup] do
    js =
      js
      |> JS.set_attribute({"data-popup-open", ""}, to: "##{trigger_id(dialog)}")
      |> JS.set_attribute({"aria-expanded", "true"}, to: "##{trigger_id(dialog)}")
      |> JS.remove_attribute("hidden", to: layers(dialog))
      |> JS.set_attribute({"data-open", ""}, to: layers(dialog))
      |> JS.remove_attribute("data-closed", to: layers(dialog))
      |> JS.push_focus()
      |> JS.focus(to: "##{popup_id(dialog)}")

    if initial_focus == :first,
      do: JS.focus_first(js, to: "##{popup_id(dialog)}"),
      else: js
  end

  @doc """
  Closes a dialog and returns the focus to whatever opened it.

  `hidden` is not removed here. The hook adds it once the exit transition has
  finished, because an element hidden mid-animation never animates.
  """
  def close(js \\ %JS{}, dialog) do
    js
    |> JS.remove_attribute("data-popup-open", to: "##{trigger_id(dialog)}")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{trigger_id(dialog)}")
    |> JS.remove_attribute("data-open", to: layers(dialog))
    |> JS.set_attribute({"data-closed", ""}, to: layers(dialog))
    |> JS.pop_focus()
  end

  @doc """
  Marks the attributes the client owns so a server render does not close a
  dialog the reader has open.
  """
  def owned_attributes(js \\ %JS{}, part)

  def owned_attributes(js, :trigger),
    do: JS.ignore_attributes(js, ["aria-expanded", "data-popup-open"], [])

  def owned_attributes(js, part) when part in [:backdrop, :popup] do
    JS.ignore_attributes(
      js,
      ["data-open", "data-closed", "data-starting-style", "data-ending-style", "hidden"],
      []
    )
  end

  # The backdrop and the popup change together, always. Base UI documents the
  # same attributes on both because they animate as one thing.
  defp layers(dialog), do: "##{backdrop_id(dialog)}, ##{popup_id(dialog)}"
end
