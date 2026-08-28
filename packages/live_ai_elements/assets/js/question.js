const OPTION = "[data-question-option]";
const SELECTED = "cn-button-variant-default";
const UNSELECTED = "cn-button-variant-outline";

export const Question = {
  mounted() {
    this.onClick = (event) => {
      const option = event.target.closest(OPTION);
      if (!option || option.disabled) return;

      const selected = this.selected();
      const value = option.dataset.questionValue;

      if (this.el.dataset.selectionMode === "multiple") {
        selected.has(value) ? selected.delete(value) : selected.add(value);
      } else {
        selected.clear();
        selected.add(value);
      }

      this.draw(selected);
    };

    this.onInput = () => this.updateSubmit(this.selected());

    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("input", this.onInput);
    this.draw(this.selected());
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("input", this.onInput);
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
      option.dataset.selected = String(active);
      option.classList.toggle(SELECTED, active);
      option.classList.toggle(UNSELECTED, !active);
    }

    for (const input of this.el.querySelectorAll("input[data-question-value]")) input.remove();

    for (const value of selected) {
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = this.el.dataset.selectedName;
      input.value = value;
      input.dataset.questionValue = value;
      this.el.append(input);
    }

    this.updateSubmit(selected);
  },

  updateSubmit(selected) {
    const text = this.el.querySelector("[data-question-input]")?.value.trim() || "";
    const submit = this.el.querySelector("[data-question-submit]");
    if (submit) submit.disabled = selected.size === 0 && text.length === 0;
  },
};
