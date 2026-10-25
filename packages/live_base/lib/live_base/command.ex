defmodule LiveBase.Command do
  @moduledoc """
  The browser behavior for a Command list.

  The hook filters rendered items. It keeps focus on the search field while
  arrow keys change the active option.
  """

  use Phoenix.Component

  @hook "LiveBase.Command.Command"

  @doc "The client hook name used by a Command root."
  def hook, do: @hook

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook command.js#Command --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Command">
      const ITEM = "[data-slot='command-item']";
      const GROUP = "[data-slot='command-group']";
      const EMPTY = "[data-slot='command-empty']";
      const INPUT = "[data-slot='command-input']";
      const Command = {
        mounted() {
          this.input = this.el.querySelector(INPUT);
          this.list = this.el.querySelector("[data-slot='command-list']");
          this.el.addEventListener("input", (event) => {
            if (event.target.matches(INPUT)) {
              this.input = event.target;
              this.filter();
            }
          });
          this.el.addEventListener("keydown", (event) => {
            if (event.target.matches(INPUT)) this.keydown(event);
          });
          this.el.addEventListener("pointermove", (event) => this.pointermove(event));
          this.el.addEventListener("mousedown", (event) => this.mousedown(event));
          this.el.addEventListener("click", (event) => this.choose(event));
          if (this.input && this.list) {
            if (!this.list.id) this.list.id = `${this.el.id}-list`;
            this.input.setAttribute("aria-controls", this.list.id);
          }
          this.filter();
        },
        updated() {
          this.input = this.el.querySelector(INPUT);
          this.list = this.el.querySelector("[data-slot='command-list']");
          this.filter();
        },
        items() {
          return [...this.el.querySelectorAll(ITEM)].filter((item) => !item.hidden && item.getAttribute("aria-disabled") !== "true");
        },
        value(item) {
          return (item.getAttribute("data-value") || item.textContent || "").replace(/\s+/g, " ").trim().toLocaleLowerCase();
        },
        filter() {
          const query = (this.input?.value || "").trim().toLocaleLowerCase();
          for (const item of this.el.querySelectorAll(ITEM)) item.hidden = query !== "" && !this.value(item).includes(query);
          for (const group of this.el.querySelectorAll(GROUP)) group.hidden = ![...group.querySelectorAll(ITEM)].some((item) => !item.hidden);
          [...this.el.querySelectorAll("[data-slot='command-separator']")].forEach((separator) => {
            let before = separator.previousElementSibling;
            let after = separator.nextElementSibling;
            while (before && (!before.matches(GROUP) || before.hidden)) before = before.previousElementSibling;
            while (after && (!after.matches(GROUP) || after.hidden)) after = after.nextElementSibling;
            separator.hidden = !before || !after;
          });
          const items = this.items();
          const empty = this.el.querySelector(EMPTY);
          if (empty) empty.hidden = items.length !== 0;
          this.select(items[0] || null);
        },
        selected() {
          return this.items().find((item) => item.getAttribute("aria-selected") === "true") || null;
        },
        select(item) {
          for (const candidate of this.el.querySelectorAll(ITEM)) {
            const selected = candidate === item;
            candidate.setAttribute("aria-selected", String(selected));
            if (selected) candidate.setAttribute("data-selected", "true");
            else candidate.removeAttribute("data-selected");
          }
          if (!this.input) return;
          if (item && !item.id) item.id = `${this.el.id}-item-${this.items().indexOf(item)}`;
          if (item) this.input.setAttribute("aria-activedescendant", item.id);
          else this.input.removeAttribute("aria-activedescendant");
        },
        keydown(event) {
          const items = this.items();
          if (items.length === 0) return;
          const from = Math.max(0, items.indexOf(this.selected()));
          let to = null;
          if (event.key === "ArrowDown") to = (from + 1) % items.length;
          if (event.key === "ArrowUp") to = (from - 1 + items.length) % items.length;
          if (event.key === "Home") to = 0;
          if (event.key === "End") to = items.length - 1;
          if (to !== null) {
            event.preventDefault();
            this.select(items[to]);
            items[to].scrollIntoView({ block: "nearest" });
            return;
          }
          if (event.key === "Enter") {
            event.preventDefault();
            this.selected()?.click();
          }
        },
        pointermove(event) {
          const item = event.target.closest(ITEM);
          if (!item || !this.el.contains(item) || item.hidden) return;
          if (item.getAttribute("aria-disabled") === "true") return;
          this.select(item);
        },
        mousedown(event) {
          if (event.target.closest(ITEM)) event.preventDefault();
        },
        choose(event) {
          const item = event.target.closest(ITEM);
          if (!item || !this.el.contains(item)) return;
          if (item.getAttribute("aria-disabled") === "true") {
            event.preventDefault();
            event.stopPropagation();
            return;
          }
          this.select(item);
          item.dispatchEvent(new CustomEvent("command-select", {
            bubbles: true,
            detail: { value: this.value(item) }
          }));
        }
      };
      export default Command;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
