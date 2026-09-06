const OPTION = "[data-question-option]";

// QuestionOption leaves the button variant implicit. Keep the full pinned
// Button variants mutually exclusive when the local selected state changes.
// Marker classes keep both variants in the DOM and do not match React.
const DEFAULT_VARIANT = "bg-primary text-primary-foreground hover:bg-primary/90";
const OUTLINE_VARIANT =
  "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50";

export const Question = {
  mounted() {
    this.onClick = (event) => {
      const option = event.target.closest(OPTION);
      if (!option || option.disabled) return;

      const selected = this.selected();
      const value = option.dataset.questionValue;

      if (this.el.dataset.selectionMode === "multiple") {
        selected.has(value) ? selected.delete(value) : selected.add(value);
      } else if (selected.has(value)) {
        selected.delete(value);
      } else {
        selected.clear();
        selected.add(value);
      }

      this.draw(selected);
    };

    this.onInput = () => this.updateSubmit(this.selected());
    this.onSubmit = (event) => this.submit(event);

    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("input", this.onInput);
    this.el.addEventListener("submit", this.onSubmit);
    this.draw(this.selected());
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("input", this.onInput);
    this.el.removeEventListener("submit", this.onSubmit);
  },

  selected() {
    return new Set(
      [...this.el.querySelectorAll(OPTION)]
        .filter((option) => option.getAttribute("aria-checked") === "true")
        .map((option) => option.dataset.questionValue),
    );
  },

  draw(selected) {
    for (const option of this.el.querySelectorAll(OPTION)) {
      const active = selected.has(option.dataset.questionValue);
      option.setAttribute("aria-checked", String(active));
      this.replaceVariant(option, active);
    }

    this.updateSubmit(selected);
  },

  replaceVariant(option, selected) {
    const from = selected ? OUTLINE_VARIANT : DEFAULT_VARIANT;
    const to = selected ? DEFAULT_VARIANT : OUTLINE_VARIANT;

    // An explicit caller variant does not change with selection upstream.
    // Replace only the complete implicit variant already rendered by the port.
    if (option.className.includes(from)) option.className = option.className.replace(from, to);
  },

  submit(event) {
    event.preventDefault();

    const selected = this.selected();
    const text = this.el.querySelector("[data-question-input]")?.value.trim() || "";
    if (selected.size === 0 && text.length === 0) return;

    const serverEvent = this.el.dataset.questionSubmitEvent;
    if (serverEvent && this.pushEvent) {
      this.pushEvent(serverEvent, { selected_values: [...selected], text });
    }
  },

  updateSubmit(selected) {
    const text = this.el.querySelector("[data-question-input]")?.value.trim() || "";
    const submit = this.el.querySelector("[data-question-submit]");
    if (submit) submit.disabled = selected.size === 0 && text.length === 0;
  },
};
