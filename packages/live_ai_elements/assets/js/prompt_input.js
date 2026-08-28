// Match the upstream textarea contract. Enter submits the parent form, while
// Shift+Enter adds a new line. Input-method composition must finish first.
export const PromptInput = {
  mounted() {
    this.composing = false;
    this.onCompositionStart = () => {
      this.composing = true;
    };
    this.onCompositionEnd = () => {
      this.composing = false;
    };
    this.onKeyDown = (event) => {
      if (event.key !== "Enter" || event.shiftKey || this.composing || event.isComposing) {
        return;
      }

      const form = this.el.form;
      const submit = form?.querySelector('button[type="submit"]');
      if (submit?.disabled) {
        return;
      }

      event.preventDefault();
      form?.requestSubmit();
    };

    this.el.addEventListener("compositionstart", this.onCompositionStart);
    this.el.addEventListener("compositionend", this.onCompositionEnd);
    this.el.addEventListener("keydown", this.onKeyDown);
  },

  destroyed() {
    this.el.removeEventListener("compositionstart", this.onCompositionStart);
    this.el.removeEventListener("compositionend", this.onCompositionEnd);
    this.el.removeEventListener("keydown", this.onKeyDown);
  },
};
