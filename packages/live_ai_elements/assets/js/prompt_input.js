// The textarea owns draft text and local files. The caller owns submission.
export const PromptInput = {
  mounted() {
    this.form = this.el.form;
    this.files = [];
    this.composing = false;
    this.submitting = false;
    const provider = this.el.closest("[data-ai-prompt-provider]");
    if (provider && !this.el.dataset.explicitValue) {
      this.el.value = provider.dataset.initialInput || "";
    }
    this.renderedValue = this.el.dataset.inputValue;
    this.el.setAttribute("data-ai-prompt-draft", "");

    this.onCompositionStart = () => { this.composing = true; };
    this.onCompositionEnd = () => { this.composing = false; };
    this.onKeyDown = (event) => {
      if (event.defaultPrevented || this.composing || event.isComposing) return;
      if (event.key === "Backspace" && this.el.value === "" && this.files.length) {
        event.preventDefault();
        this.remove(this.files.at(-1).id);
        return;
      }
      if (event.key !== "Enter" || event.shiftKey) return;
      const submit = this.form?.querySelector('button[type="submit"]');
      if (submit?.disabled) return;
      event.preventDefault();
      this.form?.requestSubmit();
    };
    this.onChange = (event) => {
      if (!event.target.matches("[data-ai-prompt-files]")) return;
      this.add(event.target.files);
      event.target.value = "";
    };
    this.onPaste = (event) => {
      const files = [...(event.clipboardData?.items || [])]
        .filter((item) => item.kind === "file").map((item) => item.getAsFile()).filter(Boolean);
      if (files.length) {
        event.preventDefault();
        this.add(files);
      }
    };
    this.onDragOver = (event) => {
      if ([...(event.dataTransfer?.types || [])].includes("Files")) event.preventDefault();
    };
    this.onDrop = (event) => {
      if (!event.dataTransfer?.files?.length) return;
      event.preventDefault();
      this.add(event.dataTransfer.files);
    };
    this.onRemove = (event) => this.remove(event.detail?.id);
    this.onClear = () => this.clear();
    this.onSubmit = (event) => {
      if (!this.form?.dataset.submitEvent) return;
      event.preventDefault();
      event.stopPropagation();
      this.submit();
    };

    this.el.addEventListener("compositionstart", this.onCompositionStart);
    this.el.addEventListener("compositionend", this.onCompositionEnd);
    this.el.addEventListener("keydown", this.onKeyDown);
    this.el.addEventListener("paste", this.onPaste);
    this.form?.addEventListener("change", this.onChange);
    this.form?.addEventListener("submit", this.onSubmit);
    this.form?.addEventListener("live-ai:prompt-remove", this.onRemove);
    this.form?.addEventListener("live-ai:prompt-clear", this.onClear);
    this.bindDropTarget();
  },

  beforeUpdate() {
    this.draftValue = this.el.value;
  },

  updated() {
    // An attachment or status patch must not replace a local draft. A changed
    // server value still applies, for example when the caller picks a suggestion.
    const renderedValue = this.el.dataset.inputValue;
    if (renderedValue !== this.renderedValue) {
      this.el.value = renderedValue || "";
    } else if (this.draftValue !== undefined) {
      this.el.value = this.draftValue;
    }
    this.renderedValue = renderedValue;
    this.draftValue = undefined;
    // LiveView skips hooks for equal markup, but morphdom still resets an
    // unfocused textarea value. This client marker ensures the hook runs.
    this.el.setAttribute("data-ai-prompt-draft", "");
    this.bindDropTarget();
  },

  destroyed() {
    this.el.removeEventListener("compositionstart", this.onCompositionStart);
    this.el.removeEventListener("compositionend", this.onCompositionEnd);
    this.el.removeEventListener("keydown", this.onKeyDown);
    this.el.removeEventListener("paste", this.onPaste);
    this.form?.removeEventListener("change", this.onChange);
    this.form?.removeEventListener("submit", this.onSubmit);
    this.form?.removeEventListener("live-ai:prompt-remove", this.onRemove);
    this.form?.removeEventListener("live-ai:prompt-clear", this.onClear);
    this.dropTarget?.removeEventListener("dragover", this.onDragOver);
    this.dropTarget?.removeEventListener("drop", this.onDrop);
    for (const item of this.files) URL.revokeObjectURL(item.url);
  },

  bindDropTarget() {
    const target = this.form?.dataset.globalDrop === "true" ? document : this.form;
    if (target === this.dropTarget) return;
    this.dropTarget?.removeEventListener("dragover", this.onDragOver);
    this.dropTarget?.removeEventListener("drop", this.onDrop);
    this.dropTarget = target;
    target?.addEventListener("dragover", this.onDragOver);
    target?.addEventListener("drop", this.onDrop);
  },

  picker() {
    return this.form?.querySelector("[data-ai-prompt-files]");
  },

  add(incoming) {
    if (this.el.disabled || this.el.readOnly) return;
    const files = [...incoming];
    const patterns = (this.picker()?.accept || "").split(",").map((part) => part.trim().toLowerCase()).filter(Boolean);
    const accepted = files.filter((file) => !patterns.length || patterns.some((pattern) => {
      if (pattern.startsWith(".")) return file.name.toLowerCase().endsWith(pattern);
      if (pattern.endsWith("/*")) return file.type.toLowerCase().startsWith(pattern.slice(0, -1));
      return file.type.toLowerCase() === pattern;
    }));
    if (files.length && !accepted.length) {
      this.error("accept", "No files match the accepted types.");
      return;
    }
    const maxSize = Number(this.form?.dataset.maxFileSize);
    const sized = accepted.filter((file) => !maxSize || file.size <= maxSize);
    if (accepted.length && !sized.length) {
      this.error("max_file_size", "All files exceed the maximum size.");
      return;
    }
    const limit = this.form?.dataset.maxFiles;
    const capacity = limit == null ? sized.length : Math.max(0, Number(limit) - this.files.length);
    if (sized.length > capacity) this.error("max_files", "Too many files. Some were not added.");
    for (const file of sized.slice(0, capacity)) {
      this.files.push({ id: crypto.randomUUID(), file, url: URL.createObjectURL(file) });
    }
    this.changed();
  },

  remove(id) {
    for (const item of this.files.filter((item) => item.id === id)) URL.revokeObjectURL(item.url);
    this.files = this.files.filter((item) => item.id !== id);
    this.changed();
  },

  clear() {
    for (const item of this.files) URL.revokeObjectURL(item.url);
    this.files = [];
    this.changed();
  },

  changed() {
    if (!this.files.length && this.form?.dataset.syncHiddenInput === "true" && this.picker()) {
      this.picker().value = "";
    }
    this.notify("files-change", { files: this.files.map(({ id, file, url }) => ({
      id, type: "file", filename: file.name, mediaType: file.type, url,
    })) }, this.form?.dataset.filesChangeEvent);
  },

  error(code, message) {
    this.notify("error", { code, message }, this.form?.dataset.errorEvent);
  },

  notify(name, detail, serverEvent) {
    this.form?.dispatchEvent(new CustomEvent(`live-ai:prompt-${name}`, { detail, bubbles: true }));
    if (serverEvent) this.pushEventTo(this.eventTarget(), serverEvent, detail);
  },

  eventTarget() {
    return this.form?.getAttribute("phx-target") || this.form;
  },

  async submit() {
    if (this.submitting || this.el.disabled) return;
    this.submitting = true;
    const text = this.el.value;
    const submitted = [...this.files];
    try {
      const files = await Promise.all(submitted.map(({ file }) => new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve({ type: "file", filename: file.name, mediaType: file.type, url: reader.result });
        reader.onerror = () => reject(reader.error);
        reader.readAsDataURL(file);
      })));
      const replies = await this.pushEventTo(this.eventTarget(), this.form.dataset.submitEvent, { text, files });
      const response = replies.find((result) => result.status === "fulfilled");
      if (!response) throw new Error("The message was not acknowledged.");
      if (response.value.reply?.ok === false) return;
      if (this.el.value === text) this.el.value = "";
      const ids = new Set(submitted.map((item) => item.id));
      for (const item of this.files.filter((item) => ids.has(item.id))) URL.revokeObjectURL(item.url);
      this.files = this.files.filter((item) => !ids.has(item.id));
      this.changed();
    } catch {
      this.error("submit", "The message could not be submitted.");
    } finally {
      this.submitting = false;
    }
  },
};
