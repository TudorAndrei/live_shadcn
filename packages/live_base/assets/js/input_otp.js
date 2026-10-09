// Mirrors the native OTP input into the visible upstream slot markup.
//
// The input remains the only form control. Slots are display nodes, so typing,
// paste, selection, and native input/change events keep their normal browser
// meaning.

const controllers = new WeakMap();
let installed = false;

export function installInputOtpBehavior() {
  if (installed) return;
  installed = true;

  const style = document.createElement("style");
  style.textContent = `[data-input-otp]::selection {
    background: transparent !important;
    color: transparent !important;
  }`;
  document.head.appendChild(style);

  const mount = (element) => {
    if (controllers.has(element)) return;
    const controller = Object.assign(Object.create(InputOtp), { el: element });
    controller.mounted();
    controllers.set(element, controller);
  };

  const unmount = (element) => {
    const controller = controllers.get(element);
    if (!controller) return;
    controller.destroyed();
    controllers.delete(element);
  };

  const roots = (node) => {
    if (!(node instanceof Element)) return [];
    return [
      ...(node.matches("[data-input-otp-container]") ? [node] : []),
      ...node.querySelectorAll("[data-input-otp-container]"),
    ];
  };

  for (const root of document.querySelectorAll("[data-input-otp-container]")) mount(root);

  const observer = new MutationObserver((records) => {
    const updated = new Set();

    for (const record of records) {
      for (const node of record.addedNodes) for (const root of roots(node)) mount(root);
      for (const node of record.removedNodes) for (const root of roots(node)) unmount(root);

      const root =
        record.target instanceof Element
          ? record.target.closest("[data-input-otp-container]")
          : record.target.parentElement?.closest("[data-input-otp-container]");
      const controller = root && controllers.get(root);
      if (controller && !controller.writing) updated.add(controller);
    }

    for (const controller of updated) controller.updated();
  });

  observer.observe(document.documentElement, {
    attributes: true,
    characterData: true,
    childList: true,
    subtree: true,
  });
}

export const InputOtp = {
  mounted() {
    this.previousSelection = [null, null, "none"];
    this.onInput = (event) => this.inputChanged(event);
    this.onFocus = () => this.focused();
    this.onBlur = () => this.sync();
    this.onSelectionChange = () => this.selectionChanged();
    this.onResize = () => this.setRootHeight();

    if (!this.bindInput()) return;

    document.addEventListener("selectionchange", this.onSelectionChange, true);
    if (typeof ResizeObserver !== "undefined") {
      this.resizeObserver = new ResizeObserver(this.onResize);
      this.resizeObserver.observe(this.el);
    }
    this.setRootHeight();
    this.sync();
  },

  updated() {
    if (!this.bindInput()) return;
    this.lastValue = this.input.value;
    this.setRootHeight();
    this.sync();
  },

  destroyed() {
    this.unbindInput();
    document.removeEventListener("selectionchange", this.onSelectionChange, true);
    this.resizeObserver?.disconnect();
    clearTimeout(this.writingTimer);
  },

  bindInput() {
    const input = this.el.querySelector(":scope > div > input[data-input-otp]");
    if (!(input instanceof HTMLInputElement)) return false;
    if (input === this.input) return true;

    this.unbindInput();
    this.input = input;
    this.lastValue = input.value;
    input.addEventListener("input", this.onInput);
    input.addEventListener("focus", this.onFocus);
    input.addEventListener("blur", this.onBlur);
    return true;
  },

  unbindInput() {
    this.input?.removeEventListener("input", this.onInput);
    this.input?.removeEventListener("focus", this.onFocus);
    this.input?.removeEventListener("blur", this.onBlur);
  },

  slots() {
    return [...this.el.querySelectorAll("[data-slot='input-otp-slot']")]
      .filter((slot) => slot.closest("[data-input-otp-container]") === this.el)
      .sort(
        (left, right) =>
          Number(left.dataset.inputOtpIndex) - Number(right.dataset.inputOtpIndex),
      );
  },

  focused() {
    const maximum = this.maximumLength();
    const start = Math.min(this.input.value.length, maximum - 1);
    this.input.setSelectionRange(Math.max(start, 0), this.input.value.length);
    this.selectionChanged();
  },

  inputChanged(event) {
    if (this.syncing) return;

    const value = this.limitedValue(this.input.value);

    if (!this.accepts(value)) {
      event.stopImmediatePropagation();
      this.input.value = this.lastValue;
      this.selectionChanged();
      return;
    }

    this.lastValue = value;

    if (value !== this.input.value) {
      event.stopImmediatePropagation();
      this.syncing = true;
      this.input.value = value;
      this.sync();
      this.input.dispatchEvent(new Event("input", { bubbles: true }));
      this.syncing = false;
      return;
    }

    this.selectionChanged();
  },

  selectionChanged() {
    if (document.activeElement !== this.input) {
      this.sync();
      return;
    }

    const value = this.input.value;
    const maximum = this.maximumLength();
    let start = this.input.selectionStart;
    let end = this.input.selectionEnd;
    let direction = this.input.selectionDirection || "none";

    if (value.length !== 0 && start !== null && end !== null) {
      const singleCaret = start === end;
      const inserting = singleCaret && start === value.length && value.length < maximum;

      if (singleCaret && !inserting) {
        if (start === 0) {
          end = 1;
          direction = "forward";
        } else if (start === maximum) {
          start -= 1;
          direction = "backward";
        } else if (maximum > 1 && value.length > 1) {
          let offset = 0;
          direction = start < this.previousSelection[1] ? "backward" : "forward";
          const wasInserting =
            this.previousSelection[0] === this.previousSelection[1] &&
            this.previousSelection[0] < maximum;

          if (direction === "backward" && !wasInserting) offset = -1;
          start += offset;
          end = start + 1;
        }

        this.input.setSelectionRange(start, end, direction);
      }
    }

    this.previousSelection = [start, end, direction];
    this.sync();
  },

  sync() {
    if (!(this.input instanceof HTMLInputElement)) return;

    const value = this.input.value;
    const focused = document.activeElement === this.input;
    const start = this.input.selectionStart;
    const end = this.input.selectionEnd;

    this.writing = true;

    for (const slot of this.slots()) {
      const index = Number(slot.dataset.inputOtpIndex);
      const char = value[index] || "";
      const active =
        focused && start !== null && end !== null &&
          ((start === end && index === start) || (index >= start && index < end));
      const fakeCaret = active && char === "";

      slot.setAttribute("data-active", String(active));
      slot.replaceChildren(document.createTextNode(char));

      if (fakeCaret) {
        const caret = document.createElement("div");
        caret.className = "cn-input-otp-caret pointer-events-none absolute inset-0 flex items-center justify-center";
        const line = document.createElement("div");
        line.className = "cn-input-otp-caret-line";
        caret.append(line);
        slot.append(caret);
      }
    }

    this.updateOutput(value);
    clearTimeout(this.writingTimer);
    this.writingTimer = setTimeout(() => {
      this.writing = false;
    }, 0);
  },

  updateOutput(value) {
    const selector = this.input.getAttribute("data-lb-input-otp-output");
    if (!selector) return;

    const output = document.querySelector(selector);
    if (!output) return;

    const empty = this.input.getAttribute("data-lb-input-otp-empty") || "";
    const prefix = this.input.getAttribute("data-lb-input-otp-prefix") || "";
    output.textContent = value === "" ? empty : `${prefix}${value}`;
  },

  accepts(value) {
    const pattern = this.input.getAttribute("pattern");
    if (!pattern || value.length === 0) return true;

    try {
      return new RegExp(pattern).test(value);
    } catch {
      return true;
    }
  },

  limitedValue(value) {
    const maximum = this.maximumLength();
    return maximum > 0 ? value.slice(0, maximum) : value;
  },

  maximumLength() {
    return this.input.maxLength > 0 ? this.input.maxLength : 0;
  },

  setRootHeight() {
    this.el.style.setProperty("--root-height", `${this.el.clientHeight}px`);
  },
};
