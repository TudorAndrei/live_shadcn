// The server renders the controls. This hook owns client navigation, answers,
// validation, shortcuts, and the ARIA relations that the React primitive owns.
export const Questionnaire = {
  mounted() {
    this.onChange = (event) => this.change(event);
    this.onClick = (event) => this.click(event);
    this.onKeydown = (event) => this.keydown(event);
    this.onReset = () => {
      this.reset();
      const event = this.el.getAttribute("phx-reset");
      if (event) this.pushEvent(event, {});
    };
    this.onSubmit = (event) => this.submit(event);
    this.el.addEventListener("change", this.onChange);
    this.el.addEventListener("input", this.onChange);
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("keydown", this.onKeydown);
    this.el.addEventListener("reset", this.onReset);
    this.el.addEventListener("submit", this.onSubmit);
    this.handleEvent("questionnaire:submitted", ({ id }) => this.closeAcknowledgedDialog(id));
    this.observeDialogClose();
    this.current = this.controlledItem() || this.el.dataset.defaultItem || this.items()[0]?.dataset.questionnaireName;
    this.sync();
  },

  updated() {
    this.current = this.controlledItem() || this.current;
    this.sync();
  },

  destroyed() {
    this.el.removeEventListener("change", this.onChange);
    this.el.removeEventListener("input", this.onChange);
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("keydown", this.onKeydown);
    this.el.removeEventListener("reset", this.onReset);
    this.el.removeEventListener("submit", this.onSubmit);
    this.dialogObserver?.disconnect();
  },

  controlledItem() { return this.el.hasAttribute("data-controlled") ? this.el.dataset.item : null; },
  declaredItems() {
    try { return JSON.parse(this.el.dataset.lbItems || "null"); } catch { return null; }
  },
  itemConfig(item) {
    return this.declaredItems()?.find((config) => config.name === item.dataset.questionnaireName);
  },
  items() {
    const declared = this.declaredItems();
    return [...this.el.querySelectorAll("[data-slot='questionnaire-item']")].filter(
      (item) =>
        item.closest("[data-lb-questionnaire]") === this.el &&
        !item.disabled &&
        (!declared || this.itemConfig(item)?.disabled !== true),
    );
  },
  active() { return this.items().find((item) => item.dataset.questionnaireName === this.current); },
  controls(item) { return [...item.querySelectorAll("input, textarea, select")].filter((control) => !control.disabled); },

  valid(item = this.active()) {
    if (!item || !item.hasAttribute("data-required")) return true;
    return this.controls(item).some((input) => input.type === "radio" || input.type === "checkbox" ? input.checked : input.value.trim() !== "");
  },

  status(item) { return item.hasAttribute("data-skipped") ? "skipped" : this.valid(item) ? "answered" : "unanswered"; },

  setCurrent(name, target = "item") {
    if (!name || name === this.current) return;
    const previousItem = this.current;
    if (!this.controlledItem()) this.current = name;
    const detail = { item: name, previousItem };
    this.el.dispatchEvent(new CustomEvent("questionnaire:item-change", { bubbles: true, detail }));
    if (this.el.dataset.lbItemChangeEvent && this.pushEvent) this.pushEvent(this.el.dataset.lbItemChangeEvent, detail);
    this.sync(target);
  },

  change(event) {
    const item = event.target.closest("[data-slot='questionnaire-item']");
    if (!item || item.closest("[data-lb-questionnaire]") !== this.el) return;
    item.removeAttribute("data-invalid");
    item.removeAttribute("data-skipped");
    this.sync();
  },

  click(event) {
    const action = event.target.closest("[data-questionnaire-action]");
    if (!action || action.closest("[data-lb-questionnaire]") !== this.el || action.disabled) return;
    if (action.dataset.questionnaireAction === "submit") return;
    event.preventDefault();
    if (action.dataset.questionnaireAction === "next") this.next();
    if (action.dataset.questionnaireAction === "previous") this.previous();
    if (action.dataset.questionnaireAction === "skip") this.skip();
  },

  keydown(event) {
    if (event.defaultPrevented || event.isComposing || event.keyCode === 229) return;
    const active = this.active();
    if (!active) return;
    const editable =
      event.target.matches("textarea, select, input:not([type='radio']):not([type='checkbox'])") ||
        event.target.isContentEditable;
    if ((event.metaKey || event.ctrlKey) && !event.altKey && !event.shiftKey && event.key === "Enter") { event.preventDefault(); this.submitCurrent(); return; }
    if (event.metaKey || event.ctrlKey || event.altKey) return;
    if ((event.key === "ArrowUp" || event.key === "ArrowDown") && event.target.matches("input[type=radio], input[type=checkbox]")) {
      const choices = this.controls(active).filter((input) => input.type === event.target.type);
      const index = choices.indexOf(event.target);
      const next = choices[(index + (event.key === "ArrowDown" ? 1 : choices.length - 1)) % choices.length];
      if (next && next !== event.target) { event.preventDefault(); this.activate(next); }
      return;
    }
    if (!editable && event.key === "ArrowLeft") { event.preventDefault(); this.previous(); return; }
    if (!editable && event.key === "ArrowRight" && this.status(active) !== "unanswered") { event.preventDefault(); this.next(); return; }
    if (!editable && event.key === "Enter" && event.target.matches("input[type=radio], input[type=checkbox]")) { event.preventDefault(); if (event.target.checked) this.submitCurrent(); return; }
    const shortcut = this.shortcut(event.key);
    const input = shortcut && !editable && this.controls(active).find((control) => control.dataset.questionnaireShortcut === shortcut);
    if (input) { event.preventDefault(); this.activate(input); }
  },

  activate(input) {
    input.checked = input.type === "checkbox" ? !input.checked : true;
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
    input.focus();
  },

  shortcut(key) {
    if (this.el.dataset.shortcuts === "letters" && /^[a-z]$/i.test(key)) return key.toUpperCase();
    if (this.el.dataset.shortcuts === "numbers" && /^[1-9]$/.test(key)) return key;
    return null;
  },

  invalid(item) {
    if (!item || this.valid(item)) return false;
    item.setAttribute("data-invalid", "");
    this.sync("invalid");
    return true;
  },

  next() {
    const active = this.active();
    if (this.invalid(active)) return;
    const items = this.items();
    const index = items.indexOf(active);
    if (index < items.length - 1) this.setCurrent(items[index + 1].dataset.questionnaireName);
  },

  previous() {
    const items = this.items();
    const index = items.indexOf(this.active());
    if (index > 0) this.setCurrent(items[index - 1].dataset.questionnaireName);
  },

  skip() {
    const active = this.active();
    if (!active || active.hasAttribute("data-required")) return;
    active.removeAttribute("data-invalid");
    active.setAttribute("data-skipped", "");
    const items = this.items();
    const index = items.indexOf(active);
    if (index < items.length - 1) this.setCurrent(items[index + 1].dataset.questionnaireName);
    else this.el.requestSubmit();
  },

  submitCurrent() {
    const active = this.active();
    if (this.invalid(active)) return;
    const items = this.items();
    if (items.indexOf(active) === items.length - 1) this.el.requestSubmit(); else this.next();
  },

  submit(event) {
    const invalid = this.items().find((item) => !this.valid(item));
    if (invalid) {
      event.preventDefault();
      this.current = invalid.dataset.questionnaireName;
      invalid.setAttribute("data-invalid", "");
      this.sync("invalid");
      return;
    }
  },

  closeAcknowledgedDialog(id) {
    if (id !== this.el.dataset.lbCloseDialogOnSubmit) return;
    const dialogId = this.el.dataset.lbCloseDialogOnSubmit;
    document.getElementById(`${dialogId}-popup`)?.querySelector("[data-slot='dialog-close']")?.click();
  },

  observeDialogClose() {
    if (!this.el.hasAttribute("data-lb-reset-on-dialog-close")) return;
    this.dialog = this.el.closest("[data-slot='dialog-content']");
    if (!this.dialog) return;
    this.dialogOpen = this.dialog.hasAttribute("data-open");
    this.dialogObserver = new MutationObserver(() => this.dialogStateChanged());
    this.dialogObserver.observe(this.dialog, { attributes: true, attributeFilter: ["data-open"] });
  },

  dialogStateChanged() {
    const open = this.dialog.hasAttribute("data-open");
    if (open === this.dialogOpen) return;
    const wasOpen = this.dialogOpen;
    this.dialogOpen = open;
    if (wasOpen && !open) {
      this.el.reset();
      this.reset();
    }
  },

  reset() {
    this.items().forEach((item) => { item.removeAttribute("data-invalid"); item.removeAttribute("data-skipped"); });
    this.current = this.controlledItem() || this.el.dataset.defaultItem || this.items()[0]?.dataset.questionnaireName;
    queueMicrotask(() => this.sync());
  },

  focus(item, target) {
    if (!item || !target) return;
    queueMicrotask(() => requestAnimationFrame(() => requestAnimationFrame(() => {
      if (this.active() !== item) return;
      const control = target === "invalid" ? this.controls(item)[0] : null;
      (control || item).focus({ preventScroll: true });
    })));
  },

  sync(target = null) {
    const items = this.items();
    if (!items.some((item) => item.dataset.questionnaireName === this.current)) this.current = items[0]?.dataset.questionnaireName;
    const index = items.findIndex((item) => item.dataset.questionnaireName === this.current);
    for (const [position, item] of items.entries()) {
      const active = position === index;
      const invalid = item.hasAttribute("data-invalid");
      if (invalid) item.setAttribute("aria-invalid", "true");
      else item.removeAttribute("aria-invalid");
      const config = this.itemConfig(item);
      const status = this.status(item);
      item.hidden = !active;
      item.inert = !active;
      item.tabIndex = -1;
      if (active) item.removeAttribute("aria-hidden");
      else item.setAttribute("aria-hidden", "true");
      item.setAttribute("data-status", status);
      item.toggleAttribute("data-active", active);
      item.toggleAttribute("data-answered", status === "answered");
      item.querySelectorAll("[data-slot='questionnaire-choice']").forEach((choice, choiceIndex) => {
        const input = choice.querySelector("input");
        const shortcut = this.el.dataset.shortcuts && !input?.disabled ? (this.el.dataset.shortcuts === "letters" ? String.fromCharCode(65 + choiceIndex) : String(choiceIndex + 1)) : null;
        choice.toggleAttribute("data-invalid", invalid);
        choice.toggleAttribute("data-checked", Boolean(input?.checked));
        choice.toggleAttribute("data-unchecked", !input?.checked);
        choice.toggleAttribute("data-shortcut", Boolean(shortcut));
        const node = choice.querySelector("[data-slot='questionnaire-choice-shortcut']");
        if (node) { node.hidden = !shortcut; node.textContent = shortcut || ""; }
        if (input) {
          input.name = item.dataset.questionnaireName;
          input.type = item.hasAttribute("data-multiple") || config?.multiple ? "checkbox" : "radio";
          input.dataset.questionnaireShortcut = shortcut || "";
        }
      });
      const descriptions = [...item.querySelectorAll("[data-slot='questionnaire-description']")];
      const errors = [...item.querySelectorAll("[data-slot='questionnaire-error']")];
      descriptions.forEach((node, number) => { if (!node.id) this.js().setAttribute(node, "id", `questionnaire-${item.dataset.questionnaireName}-description-${number + 1}`); });
      errors.forEach((node, number) => {
        if (!node.id) this.js().setAttribute(node, "id", `questionnaire-${item.dataset.questionnaireName}-error-${number + 1}`);
        node.hidden = !invalid;
        node.toggleAttribute("data-invalid", invalid);
        if (invalid) node.setAttribute("role", "alert"); else node.removeAttribute("role");
      });
      const describedBy = [...descriptions, ...(invalid ? errors : [])].map((node) => node.id).join(" ");
      this.controls(item).forEach((input) => {
        if (invalid) input.setAttribute("aria-invalid", "true"); else input.removeAttribute("aria-invalid");
        if (describedBy) input.setAttribute("aria-describedby", describedBy); else input.removeAttribute("aria-describedby");
      });
      const event = item.dataset.lbStatusChangeEvent;
      if (event && item.dataset.lastStatus !== status && this.pushEvent) this.pushEvent(event, { name: item.dataset.questionnaireName, status });
      item.dataset.lastStatus = status;
    }
    this.el.querySelectorAll("[data-slot='questionnaire-progress']").forEach((progress) => {
      const format = progress.dataset.lbProgressFormat;
      if (format === "fraction") {
        progress.textContent = `${index + 1} / ${items.length}`;
      } else if (format === "checkpoint") {
        progress.querySelectorAll("[data-lb-progress-segment]").forEach((segment, segmentIndex) => {
          segment.classList.toggle("bg-primary", segmentIndex < index + 1);
          segment.classList.toggle("bg-muted", segmentIndex >= index + 1);
        });
        const label = progress.querySelector("[data-lb-progress-label]");
        if (label) label.textContent = `Checkpoint ${index + 1} of ${items.length}`;
      } else if (!progress.children.length) {
        progress.textContent = `Question ${index + 1} of ${items.length}`;
      }
      progress.setAttribute("aria-valuenow", String(index + 1));
      progress.setAttribute("aria-valuemax", String(items.length));
      progress.setAttribute("aria-valuetext", `Question ${index + 1} of ${items.length}`);
    });
    this.el.querySelectorAll("[data-questionnaire-action]").forEach((button) => {
      const action = button.dataset.questionnaireAction;
      const active = this.active();
      const visible = action === "previous" ? index > 0 : action === "next" ? index < items.length - 1 : action === "skip" ? !active?.hasAttribute("data-required") : index === items.length - 1;
      button.hidden = !visible;
      button.inert = !visible;
      if (visible) button.removeAttribute("aria-hidden");
      else button.setAttribute("aria-hidden", "true");
      button.tabIndex = visible ? 0 : -1;
      button.toggleAttribute("data-visible", visible);
      button.toggleAttribute("data-hidden", !visible);
      if (visible && (action === "next" || action === "submit")) button.setAttribute("aria-keyshortcuts", "Enter"); else button.removeAttribute("aria-keyshortcuts");
      const status = active ? this.status(active) : "";
      button.dataset.status = status;
      if (button.hasAttribute("data-lb-disable-unanswered")) button.disabled = status === "unanswered";
    });
    this.syncDialogName();
    this.focus(this.active(), target);
  },

  syncDialogName() {
    const dialog = this.el.closest("[data-slot='dialog-content']");
    const item = this.active();
    if (!dialog || !item) return;
    const title = item.querySelector("[data-slot='questionnaire-title']");
    const description = item.querySelector("[data-slot='questionnaire-description']");
    if (title?.id) dialog.setAttribute("aria-labelledby", title.id);
    if (description?.id) dialog.setAttribute("aria-describedby", description.id);
  },
};
