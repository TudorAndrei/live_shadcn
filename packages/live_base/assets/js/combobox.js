// A filterable listbox with an editable input. The hook keeps transient UI
// state on the client, so typing and choosing do not need a LiveView round trip.

const ITEM = "[data-slot='combobox-item']";
const GROUP = "[data-slot='combobox-group']";
const SEPARATOR = "[data-slot='combobox-separator']";
const EMPTY = "[data-slot='combobox-empty']";
const INPUT = "input[role='combobox']";
const VALUE_SEPARATOR = "\u001f";
const LIVE_REGION_MARKER = "\u2060";

export const Combobox = {
  mounted() {
    this.controllerId = this.el.getAttribute("data-combobox-controller");
    this.selected = new Set();
    this.query = "";
    this.openedBy = null;
    this.bind();
    this.readInitialValue();
    this.filter();
    this.sync({ emit: false });
  },

  updated() {
    this.bind();
    this.filter();
    this.sync({ emit: false });
  },

  destroyed() {
    this.emptyMarkerPending = false;
    clearTimeout(this.emptyMarkerStart);
    clearTimeout(this.emptyMarkerTimer);
    document.removeEventListener("pointerdown", this.onPointerDown);
    document.removeEventListener("mousedown", this.onMouseDown);
    document.removeEventListener("input", this.onInput);
    document.removeEventListener("focusin", this.onFocusIn);
    document.removeEventListener("keydown", this.onKeydown);
    document.removeEventListener("click", this.onClick);
    document.removeEventListener("pointermove", this.onPointerMove);
    document.removeEventListener("focusout", this.onFocusOut);
  },

  bind() {
    if (!this.controllerId) return;
    const controller = CSS.escape(this.controllerId);
    this.content =
      document.querySelector(
        `[data-slot='combobox-content'][data-combobox-controller="${controller}"]`,
      ) || document.getElementById(`${this.controllerId}-content`);
    this.input =
      (this.el.matches(INPUT) && this.el) ||
      this.el.querySelector(INPUT) ||
      this.content?.querySelector(INPUT) ||
      document.querySelector(`${INPUT}[data-combobox-controller="${controller}"]`) ||
      document.getElementById(`${this.controllerId}-input`);
    const anchor =
      this.el.closest("[data-slot='input-group']") ||
      this.input?.closest?.("[data-slot='input-group']");
    this.trigger =
      (this.el.matches("button") && this.el) ||
      anchor?.querySelector("[data-slot='input-group-button']") ||
      document.getElementById(`${this.controllerId}-trigger`);
    this.addons = [...(anchor?.querySelectorAll("[data-slot='input-group-addon']") || [])];
    this.labels = [
      ...document.querySelectorAll(
        `[data-combobox-label-for="${CSS.escape(this.controllerId)}"]`,
      ),
    ];
    this.positioner =
      document.querySelector(`[data-combobox-controller="${controller}"][data-lb-anchor]`) ||
      document.getElementById(`${this.controllerId}-positioner`);
    this.clear = this.anchorOrContent("[data-slot='combobox-clear']");
    this.clearParent = this.clear?.parentElement || null;
    this.hiddenInput =
      document.getElementById(`${this.controllerId}-hidden-input`) ||
      document.querySelector(
        `[data-lb-combobox-form-input="${CSS.escape(this.controllerId)}"]`,
      );
    this.chips = this.anchorOrContent("[data-slot='combobox-chips']");
    this.valueNode =
      [...(this.trigger?.childNodes || [])].find(
        (node) => node.nodeType === 3 && node.textContent.trim(),
      ) || null;
    this.valuePlaceholder ||= this.valueNode?.textContent.trim() || "";
    this.empty = this.content?.querySelector(EMPTY) || null;
    this.emptyMessage ||= this.empty?.textContent.trim() || "";

    if (this.bound) return;
    this.bound = true;
    this.onInput = (event) => this.inputChanged(event);
    this.onFocusIn = (event) => this.focusin(event);
    this.onKeydown = (event) => this.keydown(event);
    this.onClick = (event) => this.click(event);
    this.onPointerMove = (event) => this.pointermove(event);
    this.onFocusOut = () => this.focusout();
    this.onPointerDown = (event) => this.pointerdown(event);
    this.onMouseDown = (event) => this.mousedown(event);

    document.addEventListener("input", this.onInput);
    document.addEventListener("focusin", this.onFocusIn);
    document.addEventListener("keydown", this.onKeydown);
    document.addEventListener("click", this.onClick);
    document.addEventListener("pointermove", this.onPointerMove);
    document.addEventListener("focusout", this.onFocusOut);
    document.addEventListener("pointerdown", this.onPointerDown);
    document.addEventListener("mousedown", this.onMouseDown);
  },

  anchorOrContent(selector) {
    const anchor = this.el.closest("[data-slot='input-group']") || this.el;
    return this.el.matches(selector) ? this.el : anchor.querySelector(selector) || this.content?.querySelector(selector) || null;
  },

  owns(target) {
    const anchor = this.el.closest("[data-slot='input-group']") || this.el;
    return Boolean(target && (anchor.contains(target) || this.positioner?.contains(target)));
  },

  readInitialValue() {
    const initial = this.el.getAttribute("data-combobox-value") || "";
    if (initial) initial.split(VALUE_SEPARATOR).filter(Boolean).forEach((value) => this.selected.add(value));
    else if (this.el.hasAttribute("data-combobox-has-value")) this.selected.add("");

    for (const item of this.allItems()) {
      if (item.hasAttribute("data-selected")) this.selected.add(this.value(item));
    }
  },

  allItems() {
    return [...(this.content?.querySelectorAll(ITEM) || [])];
  },

  visibleItems() {
    return this.allItems().filter(
      (item) => !item.hidden && !item.hasAttribute("data-disabled"),
    );
  },

  value(item) {
    return item.getAttribute("data-value") || "";
  },

  label(item) {
    return (item.getAttribute("data-combobox-label") || item.textContent || "")
      .replace(/\s+/g, " ")
      .trim();
  },

  multiple() {
    return this.el.hasAttribute("data-combobox-multiple");
  },

  disabled() {
    return this.el.hasAttribute("data-disabled") || this.input?.disabled;
  },

  isOpen() {
    return this.el.hasAttribute("data-open");
  },

  open({ focus = true, source = null, autoHighlight = false } = {}) {
    if (this.disabled() || this.isOpen()) return;
    this.openedBy = source || document.activeElement;
    this.el.setAttribute("data-open", "");
    this.el.removeAttribute("data-closed");
    this.positioner?.removeAttribute("hidden");
    this.positioner?.setAttribute("data-open", "");
    this.positioner?.removeAttribute("data-closed");
    this.content?.removeAttribute("hidden");
    this.content?.setAttribute("data-open", "");
    this.content?.removeAttribute("data-closed");
    this.setControls(true);
    this.input?.setAttribute("aria-expanded", "true");
    this.input?.setAttribute("data-popup-open", "");
    this.trigger?.setAttribute("aria-expanded", "true");
    this.trigger?.setAttribute("data-popup-open", "");
    this.trigger?.setAttribute("data-pressed", "");
    for (const addon of this.addons) {
      if (!this.content?.contains(addon)) addon.setAttribute("aria-hidden", "true");
    }
    for (const label of this.labels) label.setAttribute("aria-hidden", "true");
    this.clear?.setAttribute("tabindex", "-1");
    this.setChipsHidden(true);
    this.filter({
      autoHighlight,
      highlightSelected: this.selected.size > 0,
      initialLiveRegion: true,
    });

    if (focus) requestAnimationFrame(() => this.input?.focus({ preventScroll: true }));
  },

  close({ restore = false } = {}) {
    if (!this.isOpen()) return;
    this.emptyMarkerPending = false;
    clearTimeout(this.emptyMarkerStart);
    clearTimeout(this.emptyMarkerTimer);
    this.emptyMarkerTimer = null;
    if (this.empty?.textContent.endsWith(LIVE_REGION_MARKER)) {
      this.empty.textContent = this.emptyMessage;
    }
    this.el.removeAttribute("data-open");
    this.el.setAttribute("data-closed", "");
    this.positioner?.removeAttribute("data-open");
    this.positioner?.setAttribute("data-closed", "");
    this.content?.removeAttribute("data-open");
    this.content?.setAttribute("data-closed", "");
    this.setControls(false);
    this.input?.setAttribute("aria-expanded", "false");
    this.input?.removeAttribute("data-popup-open");
    this.input?.removeAttribute("aria-activedescendant");
    this.trigger?.setAttribute("aria-expanded", "false");
    this.trigger?.removeAttribute("data-popup-open");
    this.trigger?.removeAttribute("data-pressed");
    for (const addon of this.addons) addon.removeAttribute("aria-hidden");
    for (const label of this.labels) label.removeAttribute("aria-hidden");
    this.clear?.removeAttribute("tabindex");
    this.setChipsHidden(false);
    this.clearHighlight();

    if (restore && this.openedBy?.isConnected) {
      this.openedBy.focus({ preventScroll: true });
    }

    this.openedBy = null;
  },

  setControls(open) {
    const controllers = [this.input, this.trigger];

    if (!open) {
      for (const controller of controllers) controller?.removeAttribute("aria-controls");
      return;
    }

    const list = this.content?.querySelector("[data-slot='combobox-list']");
    const inputControls = list?.id;
    const triggerControls =
      this.content?.getAttribute("role") === "dialog" ? this.content.id : inputControls;

    if (inputControls) this.input?.setAttribute("aria-controls", inputControls);
    if (triggerControls) this.trigger?.setAttribute("aria-controls", triggerControls);
  },

  inputChanged(event) {
    if (event.target !== this.input || this.disabled()) return;
    this.query = this.input.value;
    this.open({ focus: false, source: this.input, autoHighlight: true });
    this.filter({ autoHighlight: true });
  },

  focusin(event) {
    if (event.target === this.input && !this.disabled()) {
      if (this.skipNextInputOpen) {
        this.skipNextInputOpen = false;
        return;
      }

      this.open({
        focus: false,
        source: this.input,
        autoHighlight: false,
        highlightSelected: this.selected.size > 0,
      });
    }
  },

  click(event) {
    if (event.target === this.input) {
      this.open({ focus: false, source: this.input });
      return;
    }

    const trigger = event.target.closest("button");
    if (trigger && trigger === this.trigger) {
      event.preventDefault();
      if (this.isOpen()) this.close({ restore: true });
      else this.open({ source: trigger });
      return;
    }

    const clear = event.target.closest("[data-slot='combobox-clear']");
    if (clear && clear === this.clear) {
      event.preventDefault();
      if (!this.disabled()) this.clearValue();
      return;
    }

    const remove = event.target.closest("[data-slot='combobox-chip-remove']");
    if (remove && this.owns(remove)) {
      event.preventDefault();
      if (!this.disabled()) this.remove(remove.closest("[data-combobox-chip]"));
      return;
    }

    const item = event.target.closest(ITEM);
    if (item && this.content?.contains(item)) this.choose(item);
  },

  pointermove(event) {
    const item = event.target.closest(ITEM);
    if (!item || !this.content?.contains(item) || item.hidden || item.hasAttribute("data-disabled")) return;
    this.highlight(item);
  },

  focusout() {
    requestAnimationFrame(() => {
      const active = document.activeElement;
      if (!this.isOpen() || this.owns(active)) return;
      this.close();
    });
  },

  outsidePointerDown(event) {
    if (event.target === this.input) {
      this.inputPointerDown = true;
      requestAnimationFrame(() => {
        this.inputPointerDown = false;
      });
    }

    if (!this.isOpen()) return;
    if (this.owns(event.target)) return;
    this.close();
  },

  pointerdown(event) {
    const item = event.target.closest(ITEM);
    if (item && this.content?.contains(item)) {
      event.preventDefault();
      return;
    }

    this.outsidePointerDown(event);
  },

  mousedown(event) {
    const item = event.target.closest(ITEM);
    if (item && this.content?.contains(item)) event.preventDefault();
  },

  keydown(event) {
    if (this.disabled()) return;
    const targetIsInput = event.target === this.input;
    if (!targetIsInput) return;

    if (event.key === "Escape") {
      if (this.isOpen()) {
        event.preventDefault();
        const buttonController = this.el === this.trigger && this.trigger?.tagName === "BUTTON";
        this.close({ restore: buttonController });
      }
      return;
    }

    if (event.key === "Backspace" && this.multiple() && !this.input.value) {
      const value = [...this.selected].at(-1);
      if (value) {
        event.preventDefault();
        this.selected.delete(value);
        this.sync();
      }
      return;
    }

    if (["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) {
      event.preventDefault();
      this.open({ focus: false, source: this.input });
      this.move(event.key);
      return;
    }

    if (event.key === "Enter" && this.isOpen()) {
      const item = this.highlighted();
      if (item) {
        event.preventDefault();
        this.choose(item);
      }
    }
  },

  filter({ autoHighlight = false, highlightSelected = false, initialLiveRegion = false } = {}) {
    const query = this.query.trim().toLocaleLowerCase();
    for (const item of this.allItems()) {
      item.hidden = query !== "" && !this.label(item).toLocaleLowerCase().includes(query);
    }

    for (const group of this.content?.querySelectorAll(GROUP) || []) {
      group.hidden = ![...group.querySelectorAll(ITEM)].some((item) => !item.hidden);
    }

    for (const separator of this.content?.querySelectorAll(SEPARATOR) || []) {
      const group = separator.closest(GROUP);
      if (group) {
        separator.hidden = group.hidden;
        continue;
      }

      let before = separator.previousElementSibling;
      let after = separator.nextElementSibling;
      while (before && (before.hidden || !before.matches(GROUP))) before = before.previousElementSibling;
      while (after && (after.hidden || !after.matches(GROUP))) after = after.nextElementSibling;
      separator.hidden = !before || !after;
    }

    const items = this.visibleItems();
    const empty = items.length === 0;
    if (this.empty) {
      if (empty && initialLiveRegion) {
        this.emptyMarkerPending = true;
        const markInitialEmpty = () => {
          if (!this.emptyMarkerPending) return;

          this.emptyMarkerPending = false;
          const markedMessage = `${this.emptyMessage}${LIVE_REGION_MARKER}`;
          this.empty.textContent = markedMessage;
          clearTimeout(this.emptyMarkerTimer);
          this.emptyMarkerTimer = setTimeout(() => {
            if (this.empty?.textContent === markedMessage) {
              this.empty.textContent = this.emptyMessage;
            }

            this.emptyMarkerTimer = null;
          }, 200);
        };

        this.emptyMarkerStart = setTimeout(markInitialEmpty);
      } else if (empty && !this.emptyMarkerTimer) {
        this.empty.textContent = this.emptyMessage;
      } else if (!empty) {
        this.emptyMarkerPending = false;
        clearTimeout(this.emptyMarkerStart);
        clearTimeout(this.emptyMarkerTimer);
        this.emptyMarkerTimer = null;
        this.empty.textContent = "";
      }
    }
    this.content?.toggleAttribute("data-empty", empty);
    this.content?.querySelector("[data-slot='combobox-list']")?.toggleAttribute("data-empty", empty);

    if (
      (autoHighlight && this.el.hasAttribute("data-combobox-auto-highlight")) ||
      highlightSelected
    ) {
      this.highlight(items[0] || null);
    }
    else if (this.highlighted()?.hidden) this.clearHighlight();
  },

  highlighted() {
    return this.content?.querySelector(`${ITEM}[data-highlighted]:not([hidden])`);
  },

  clearHighlight() {
    for (const item of this.allItems()) item.removeAttribute("data-highlighted");
  },

  highlight(item) {
    this.clearHighlight();
    if (!item) {
      this.input?.removeAttribute("aria-activedescendant");
      return;
    }
    item.setAttribute("data-highlighted", "");
    if (item.id) this.input?.setAttribute("aria-activedescendant", item.id);
    item.scrollIntoView({ block: "nearest" });
  },

  move(key) {
    const items = this.visibleItems();
    if (!items.length) return;
    const current = items.indexOf(this.highlighted());
    let index = current;
    if (key === "ArrowDown") index = current < 0 ? 0 : (current + 1) % items.length;
    if (key === "ArrowUp") index = current < 0 ? items.length - 1 : (current - 1 + items.length) % items.length;
    if (key === "Home") index = 0;
    if (key === "End") index = items.length - 1;
    this.highlight(items[index]);
  },

  choose(item) {
    if (
      this.disabled() ||
        this.el.hasAttribute("data-readonly") ||
        item.hidden ||
        item.hasAttribute("data-disabled")
    )
      return;
    const value = this.value(item);
    if (!value) return;

    if (this.multiple()) {
      if (this.selected.has(value)) this.selected.delete(value);
      else this.selected.add(value);
      this.input.value = "";
      this.query = "";
      this.filter();
    } else {
      this.selected = new Set([value]);
      this.input.value = this.label(item);
      this.query = "";
      this.close();
    }

    this.sync();
  },

  remove(chip) {
    const value = chip?.getAttribute("data-combobox-chip");
    if (!value) return;
    this.selected.delete(value);
    this.sync();
    this.skipNextInputOpen = true;
    this.input?.focus({ preventScroll: true });
    queueMicrotask(() => {
      this.skipNextInputOpen = false;
    });
  },

  clearValue() {
    this.selected.clear();
    if (this.input) this.input.value = "";
    this.query = "";
    this.filter();
    this.sync();
    if (this.isOpen?.()) this.close();
    this.skipNextInputOpen = true;
    this.input?.focus({ preventScroll: true });
    queueMicrotask(() => {
      this.skipNextInputOpen = false;
    });
  },

  sync({ emit = true } = {}) {
    const values = [...this.selected];
    this.el.setAttribute("data-combobox-value", values.join(VALUE_SEPARATOR));
    this.el.toggleAttribute("data-filled", values.length > 0);

    const chips = this.el.matches?.("[data-slot='combobox-chips']") ? this.el : this.chips;
    if (chips && this.multiple()) {
      if (values.length > 0) chips.setAttribute("role", "toolbar");
      else chips.removeAttribute("role");
    }

    for (const item of this.allItems()) {
      const selected = this.selected.has(this.value(item));
      item.setAttribute("aria-selected", String(selected));
      item.toggleAttribute("data-selected", selected);
      this.syncIndicator(item, selected);
    }

    const list = this.content?.querySelector("[data-slot='combobox-list']");
    if (list) {
      list.tabIndex = -1;
      list.toggleAttribute("aria-multiselectable", this.multiple());
    }

    if (this.hiddenInput) {
      this.hiddenInput.value = this.multiple() ? "" : values[0] || "";
      this.hiddenInput.required =
        this.el.hasAttribute("data-required") && !(this.multiple() && values.length > 0);
    }

    this.renderFormValues(values);
    if (!this.multiple() && this.input && !this.input.value && values[0]) {
      const item = this.allItems().find((candidate) => this.value(candidate) === values[0]);
      if (item) this.input.value = this.label(item);
    }
    if (!this.multiple() && this.valueNode) {
      const item = this.allItems().find((candidate) => this.value(candidate) === values[0]);
      const value = item ? this.label(item) : this.valuePlaceholder;
      this.valueNode.textContent = value;
    }
    Combobox.syncClear.call(this, values);
    this.renderChips(values);

    if (emit && this.hiddenInput) {
      this.hiddenInput.dispatchEvent(new Event("input", { bubbles: true }));
      this.hiddenInput.dispatchEvent(new Event("change", { bubbles: true }));
    }
  },

  syncClear(values) {
    if (!this.clear) return;

    if (values.length === 0) {
      this.clear.toggleAttribute("data-visible", false);
      this.clear.hidden = true;
      this.clear.remove();
      return;
    }

    if (this.clear.parentElement !== this.clearParent) this.clearParent?.append(this.clear);
    this.clear.toggleAttribute("data-visible", true);
    this.clear.hidden = false;
  },

  renderChips(values) {
    if (!this.chips) return;
    this.chips.querySelectorAll("[data-combobox-chip]").forEach((chip) => chip.remove());
    const input = this.chips.querySelector(INPUT);

    for (const value of values) {
      const item = this.allItems().find((candidate) => this.value(candidate) === value);
      if (!item) continue;
      const chip = document.createElement("div");
      chip.setAttribute("data-slot", "combobox-chip");
      chip.setAttribute("data-combobox-chip", value);
      chip.setAttribute("data-combobox-generated-chip", "");
      chip.className = "cn-combobox-chip has-disabled:pointer-events-none has-disabled:cursor-not-allowed has-disabled:opacity-50";
      chip.append(document.createTextNode(this.label(item)));
      const remove = document.createElement("button");
      remove.type = "button";
      remove.setAttribute("data-slot", "combobox-chip-remove");
      remove.setAttribute("aria-disabled", "false");
      remove.className = "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 cn-button-variant-ghost cn-button-size-icon-xs cn-combobox-chip-remove";
      remove.append(this.removeIcon());
      chip.append(remove);
      this.chips.insertBefore(chip, input || null);
    }

    this.setChipsHidden(this.isOpen());
  },

  setChipsHidden(hidden) {
    const chips = this.el.matches("[data-slot='combobox-chips']") ? this.el : this.chips;

    for (const chip of chips?.querySelectorAll("[data-combobox-chip]") || []) {
      if (hidden) chip.setAttribute("aria-hidden", "true");
      else chip.removeAttribute("aria-hidden");
      const remove = chip.querySelector("[data-slot='combobox-chip-remove']");
      if (hidden) remove?.setAttribute("tabindex", "-1");
      else remove?.removeAttribute("tabindex");
    }
  },

  renderFormValues(values) {
    if (!this.hiddenInput || !this.multiple()) return;

    const formName = this.hiddenInput.getAttribute("data-lb-combobox-form-name");
    if (!formName) return;

    document
      .querySelectorAll(`[data-lb-combobox-form-value="${CSS.escape(this.controllerId)}"]`)
      .forEach((input) => input.remove());

    const inputs = values.map((value) => {
      const input = document.createElement("input");
      input.type = "hidden";
      input.setAttribute("data-lb-combobox-form-value", this.controllerId);
      input.name = formName;
      input.value = value;
      input.disabled = this.disabled();

      const form = this.hiddenInput.getAttribute("form");
      if (form) input.setAttribute("form", form);

      return input;
    });

    this.hiddenInput.after(...inputs);
  },

  syncIndicator(item, selected) {
    const existing = item.querySelector(".cn-combobox-item-indicator");

    if (!selected) {
      existing?.remove();
      return;
    }

    if (existing) return;

    const indicator = document.createElement("span");
    indicator.setAttribute("aria-hidden", "true");
    indicator.className = "cn-combobox-item-indicator";
    indicator.append(this.checkIcon());
    item.append(indicator);
  },

  removeIcon() {
    const namespace = "http://www.w3.org/2000/svg";
    const icon = document.createElementNS(namespace, "svg");
    icon.setAttribute("aria-hidden", "true");
    icon.setAttribute("fill", "none");
    icon.setAttribute("viewBox", "0 0 24 24");
    icon.setAttribute("stroke", "currentColor");
    icon.setAttribute("stroke-width", "2");
    icon.setAttribute("stroke-linecap", "round");
    icon.setAttribute("stroke-linejoin", "round");
    icon.setAttribute(
      "class",
      "lucide lucide-x cn-combobox-chip-indicator-icon pointer-events-none",
    );

    for (const d of ["M18 6 6 18", "m6 6 12 12"]) {
      const path = document.createElementNS(namespace, "path");
      path.setAttribute("d", d);
      icon.append(path);
    }

    return icon;
  },

  checkIcon() {
    const namespace = "http://www.w3.org/2000/svg";
    const icon = document.createElementNS(namespace, "svg");
    icon.setAttribute("aria-hidden", "true");
    icon.setAttribute("fill", "none");
    icon.setAttribute("viewBox", "0 0 24 24");
    icon.setAttribute("stroke", "currentColor");
    icon.setAttribute("stroke-width", "2");
    icon.setAttribute("stroke-linecap", "round");
    icon.setAttribute("stroke-linejoin", "round");
    icon.setAttribute("class", "cn-combobox-item-indicator-icon pointer-events-none");

    const path = document.createElementNS(namespace, "path");
    path.setAttribute("d", "M20 6 9 17l-5-5");
    icon.append(path);
    return icon;
  },
};
