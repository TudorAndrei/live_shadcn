defmodule LiveBase.Tabs do
  @moduledoc """
  The behavior behind a set of panels of which exactly one is shown.

  ## What the recipe owns

  Tabs are a radio group that happens to reveal something. Choosing one is
  choosing instead of the others, so the command that activates a tab is the
  one that deactivates the rest — a tab set with two active tabs is not a tab
  set with a styling problem, it is two panels on top of each other.

  ## The attribute contract

  | Element | Attribute | When |
  |---|---|---|
  | tab | `aria-selected` | `true` on the active one |
  | tab | `data-active` | present on the active one |
  | panel | `data-hidden` | present on every panel but one |
  | root, list, tab, panel | `data-orientation` | always |

  ## Keyboard

  The APG asks for arrow keys along the row and Home and End at its ends. That
  is the one thing here a `JS` command cannot do: `phx-key` filters one key per
  binding, and one element cannot carry four of them.

  So the `LiveBase.Roving` hook sits on the list and works out which tab a key
  means, then clicks it. What choosing a tab *does* stays in the command on the
  tab itself. The hook decides which, never what.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @hook "LiveBase.Tabs.Roving"

  @doc "The client hook name the tab list declares in `phx-hook`."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook roving.js#Roving --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Roving">
      const NEXT = {
        horizontal: "ArrowRight",
        vertical: "ArrowDown"
      };
      const PREVIOUS = {
        horizontal: "ArrowLeft",
        vertical: "ArrowUp"
      };
      const SUBMENU_POINTER_DELAY = 100;
      const Roving = {
        mounted() {
          this.optionNavigation = this.el.getAttribute("data-lb-roving") === "option";
          this.pointerNavigation = true;
          this.onKeydown = (event) => this.keydown(event);
          this.onPointermove = (event) => this.pointermove(event);
          this.onPointerout = (event) => this.pointerout(event);
          this.onPointerleave = () => this.cancelSubmenuOpen();
          this.onClick = () => this.cancelSubmenuOpen();
          this.el.addEventListener("keydown", this.onKeydown);
          this.el.addEventListener("pointermove", this.onPointermove);
          this.el.addEventListener("pointerout", this.onPointerout);
          this.el.addEventListener("pointerleave", this.onPointerleave);
          this.el.addEventListener("click", this.onClick);
          if (this.optionNavigation) {
            const positioner = this.el.closest("[data-lb-anchor]");
            this.anchor = document.getElementById(positioner?.getAttribute("data-lb-anchor"));
            this.markPointer = () => this.pointerNavigation = true;
            this.markKeyboard = () => this.pointerNavigation = false;
            this.anchor?.addEventListener("pointerdown", this.markPointer);
            this.anchor?.addEventListener("keydown", this.markKeyboard);
          }
        },
        destroyed() {
          this.cancelSubmenuOpen();
          this.el.removeEventListener("keydown", this.onKeydown);
          this.el.removeEventListener("pointermove", this.onPointermove);
          this.el.removeEventListener("pointerout", this.onPointerout);
          this.el.removeEventListener("pointerleave", this.onPointerleave);
          this.el.removeEventListener("click", this.onClick);
          this.anchor?.removeEventListener("pointerdown", this.markPointer);
          this.anchor?.removeEventListener("keydown", this.markKeyboard);
        },
        items() {
          return [...this.el.querySelectorAll(this.itemSelector())].filter((item) => item.closest("[data-lb-roving]") === this.el && !item.hasAttribute("data-disabled") && item.offsetParent);
        },
        itemSelector() {
          const role = this.el.getAttribute("data-lb-roving") || "tab";
          return role === "menuitem" ? "[role^='menuitem']" : `[role='${role}']`;
        },
        pointermove(event) {
          const item = event.target.closest(this.itemSelector());
          if (this.optionNavigation) {
            if (event.pointerType === "touch") return;
            this.pointerNavigation = true;
            if (!this.items().includes(item)) return;
            this.highlight(item);
            item.focus({ preventScroll: true });
            return;
          }
          if (!item || item.closest("[data-lb-roving]") !== this.el) return;
          this.closeOpenSubmenus(item);
          if (item.getAttribute("aria-haspopup") !== "menu") return;
          if (item.getAttribute("aria-expanded") === "true") return;
          this.cancelSubmenuOpen();
          this.submenuTimer = setTimeout(() => {
            if (item.matches(":hover") && item.offsetParent && item.getAttribute("aria-expanded") !== "true") item.click();
          }, SUBMENU_POINTER_DELAY);
        },
        pointerout(event) {
          if (!this.optionNavigation || !this.pointerNavigation || event.pointerType === "touch") return;
          const items = this.items();
          const item = event.target.closest(this.itemSelector());
          const next = event.relatedTarget?.closest?.(this.itemSelector());
          if (!items.includes(item) || items.includes(next)) return;
          this.highlight(null);
          if (this.el.contains(document.activeElement)) this.el.focus({ preventScroll: true });
        },
        highlight(item) {
          const attribute = this.el.getAttribute("data-lb-highlight");
          if (!attribute) return;
          for (const sibling of this.items()) sibling.removeAttribute(attribute);
          item?.setAttribute(attribute, "");
        },
        cancelSubmenuOpen() {
          clearTimeout(this.submenuTimer);
          this.submenuTimer = null;
        },
        closeOpenSubmenus(except) {
          for (const trigger of this.items().filter((item) => item !== except && item.getAttribute("aria-haspopup") === "menu" && item.getAttribute("aria-expanded") === "true")) trigger.click();
        },
        deepestOpenSubmenuTrigger() {
          let menu = this.el;
          let trigger = null;
          while (menu) {
            const child = [...menu.querySelectorAll("[aria-haspopup='menu'][aria-expanded='true']")].find((item) => item.closest("[data-lb-roving]") === menu);
            if (!child) break;
            trigger = child;
            menu = document.getElementById(child.getAttribute("aria-controls"));
          }
          return trigger;
        },
        keydown(event) {
          this.pointerNavigation = false;
          this.cancelSubmenuOpen();
          const active = document.activeElement;
          if ((event.key === "Enter" || event.key === " ") && this.items().includes(active)) {
            event.preventDefault();
            active.click();
            return;
          }
          if (event.key === "ArrowRight" && active?.getAttribute("aria-haspopup") === "menu") {
            event.preventDefault();
            const popup = document.getElementById(active.getAttribute("aria-controls"));
            active.click();
            requestAnimationFrame(() => {
              if (active.getAttribute("aria-expanded") === "true") popup?.focus();
            });
            return;
          }
          let closingTrigger = event.key === "Escape" ? this.deepestOpenSubmenuTrigger() : null;
          if (!closingTrigger && ["ArrowLeft", "Escape"].includes(event.key) && this.el.hasAttribute("data-lb-submenu")) closingTrigger = document.getElementById(this.el.getAttribute("data-lb-parent-trigger"));
          if (closingTrigger) {
            event.preventDefault();
            event.stopPropagation();
            closingTrigger.click();
            closingTrigger.focus();
            return;
          }
          const orientation = this.el.getAttribute("data-lb-orientation") || "horizontal";
          const items = this.items();
          const from = items.indexOf(document.activeElement);
          if (items.length === 0) return;
          const to = this.target(event.key, orientation, from, items.length);
          if (to === null) return;
          event.preventDefault();
          this.move(items, to);
        },
        move(items, to) {
          this.closeOpenSubmenus(items[to]);
          this.highlight(items[to]);
          if (this.el.hasAttribute("data-lb-activate")) items[to].click();
          items[to].focus();
        },
        target(key, orientation, from, count) {
          const loop = this.el.hasAttribute("data-lb-loop");
          const step = (by) => {
            const next = from + by;
            if (next >= 0 && next < count) return next;
            return loop ? (next + count) % count : null;
          };
          switch (key) {
            case NEXT[orientation]: return from === -1 ? 0 : step(1);
            case PREVIOUS[orientation]: return from === -1 ? count - 1 : step(-1);
            case "Home": return 0;
            case "End": return count - 1;
            default: return null;
          }
        }
      };
      export default Roving;
    </script>
    <%!-- /colocated-hook --%>
    """
  end

  @doc "The id of a tab, given the tab set and the tab's own value."
  def tab_id(tabs, value), do: "#{tabs}-tab-#{value}"

  @doc "The id of a panel, given the tab set and its tab's value."
  def panel_id(tabs, value), do: "#{tabs}-panel-#{value}"

  @doc """
  Activates one tab and deactivates the rest.

  ## Options

    * `:tabs` — required, the id of the tab set
    * `:value` — required, the value of the tab being activated
    * `:focus` — whether to move the focus to it. True for a keypress, false
      for a click, which has already moved it.
  """
  def activate(js \\ %JS{}, opts) do
    tabs = Keyword.fetch!(opts, :tabs)
    value = Keyword.fetch!(opts, :value)
    tab = "##{tab_id(tabs, value)}"
    panel = "##{panel_id(tabs, value)}"

    js
    |> deactivate(tabs, tab)
    |> JS.set_attribute({"aria-selected", "true"}, to: tab)
    |> JS.set_attribute({"data-active", ""}, to: tab)
    |> JS.set_attribute({"tabindex", "0"}, to: tab)
    |> JS.remove_attribute("data-hidden", to: panel)
    |> JS.remove_attribute("hidden", to: panel)
    |> then(&if Keyword.get(opts, :focus, false), do: JS.focus(&1, to: tab), else: &1)
  end

  # Every other tab in this set, found by role. A caller who built the set with
  # a comprehension has no list of ids to keep in step.
  defp deactivate(js, tabs, except) do
    others = "##{tabs} [role='tab']:not(#{except})"

    js
    |> JS.set_attribute({"aria-selected", "false"}, to: others)
    |> JS.remove_attribute("data-active", to: others)
    |> JS.set_attribute({"tabindex", "-1"}, to: others)
    |> JS.set_attribute({"data-hidden", ""}, to: "##{tabs} [role='tabpanel']")
    |> JS.set_attribute({"hidden", ""}, to: "##{tabs} [role='tabpanel']")
  end

  @doc """
  Marks the attributes the client owns so a server render does not move the
  reader back to the tab they started on.
  """
  def owned_attributes(js \\ %JS{}, part)

  def owned_attributes(js, :tab),
    do: JS.ignore_attributes(js, ["aria-selected", "data-active", "tabindex"], [])

  def owned_attributes(js, :panel),
    do: JS.ignore_attributes(js, ["data-hidden", "hidden"], [])
end
