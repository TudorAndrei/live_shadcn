// The official streaming example starts with its complete transcript.
// Replay reveals three characters per frame and keeps copy disabled until
// the corresponding block is complete.
export const ShadcnCodeStreaming = {
  mounted() {
    this.phase = this.el.dataset.phase;
    this.handleReplay = () => this.replay();
    this.el.addEventListener("storybook:stream-replay", this.handleReplay);
    this.handleDownload = event => {
      const button = event.target.closest("[data-download-value]");
      if (!button) return;
      const url = URL.createObjectURL(new Blob([button.dataset.downloadValue], { type: "text/plain" }));
      const link = document.createElement("a");
      link.href = url;
      link.download = button.dataset.downloadName;
      link.click();
      URL.revokeObjectURL(url);
    };
    this.el.addEventListener("storybook:download", this.handleDownload);
  },
  destroyed() {
    clearTimeout(this.timer);
    this.el.removeEventListener("storybook:stream-replay", this.handleReplay);
    this.el.removeEventListener("storybook:download", this.handleDownload);
  },
  beforeUpdate() {
    const active = document.activeElement;
    this.focused = this.el.contains(active) ? active.id : null;
  },
  updated() {
    if (this.phase !== this.el.dataset.phase) {
      clearTimeout(this.timer);
      this.streaming = false;
      this.phase = this.el.dataset.phase;
      if (this.phase === "messages-2") this.replayConversation();
    }
    if (this.focused) document.getElementById(this.focused)?.focus({ preventScroll: true });
  },
  replayConversation() {
    const response = this.el.querySelectorAll("[data-slot=message]")[1];
    if (!response) return;
    const action = this.el.querySelector("[id$='-action-1']");
    if (action) action.hidden = true;
    const walker = document.createTreeWalker(response, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) {
      const node = walker.currentNode;
      if (!node.parentElement.closest("button, [aria-live], .sr-only")) {
        nodes.push({ node, text: node.textContent });
      }
    }
    const rows = [...response.querySelectorAll("[data-slot=trace-line]")].map(row => ({ row, status: row.getAttribute("data-status") }));
    rows.forEach(({ row }) => row.setAttribute("data-status", "running"));
    const copies = [...response.querySelectorAll("[data-slot=code-block-copy-button]")];
    copies.forEach(copy => { copy.disabled = true; });
    nodes.forEach(({ node }) => { node.textContent = ""; });
    let length = 0;
    const total = nodes.reduce((sum, { text }) => sum + text.length, 0);
    const tick = () => {
      length = Math.min(length + 6, total);
      let available = length;
      for (const { node, text } of nodes) {
        node.textContent = text.slice(0, available);
        available = Math.max(0, available - text.length);
      }
      if (length < total) this.timer = setTimeout(tick, 16);
      else {
        rows.forEach(({ row, status }) => {
          if (status === null) row.removeAttribute("data-status");
          else row.setAttribute("data-status", status);
        });
        copies.forEach(copy => { copy.disabled = false; });
        if (action) action.hidden = false;
      }
    };
    tick();
  },
  replay() {
    if (this.streaming) return;
    this.streaming = true;
    const replay = this.el.querySelector("button:last-child");
    replay.disabled = true;
    const blocks = [...this.el.querySelectorAll("[data-slot=code-block]")].map(root => {
      const walker = document.createTreeWalker(root.querySelector("code"), NodeFilter.SHOW_TEXT);
      const nodes = [];
      while (walker.nextNode()) nodes.push({ node: walker.currentNode, text: walker.currentNode.textContent });
      const rows = [...root.querySelectorAll("[data-slot=code-block-line]")];
      const copy = root.querySelector("[data-slot=code-block-copy-button]");
      if (copy) copy.disabled = true;
      root.hidden = true;
      nodes.forEach(({ node }) => { node.textContent = ""; });
      rows.forEach(row => { row.hidden = true; });
      return { root, nodes, rows, copy, length: nodes.reduce((sum, item) => sum + item.text.length, 0) };
    });
    let length = 0;
    const total = blocks.reduce((sum, block) => sum + block.length, 0);
    const tick = () => {
      length = Math.min(length + 3, total);
      let remaining = length;
      for (const block of blocks) {
        block.root.hidden = remaining <= 0;
        let available = Math.max(0, remaining);
        for (const { node, text } of block.nodes) {
          node.textContent = text.slice(0, available);
          const row = node.parentElement.closest("[data-slot=code-block-line]");
          if (row && available > 0) row.hidden = false;
          available = Math.max(0, available - text.length);
        }
        if (block.copy) block.copy.disabled = remaining < block.length;
        remaining -= block.length;
      }
      if (length < total) this.timer = setTimeout(tick, 16);
      else {
        this.streaming = false;
        replay.disabled = false;
        blocks.forEach(block => block.rows.forEach(row => { row.hidden = false; }));
      }
    };
    tick();
  },
};
