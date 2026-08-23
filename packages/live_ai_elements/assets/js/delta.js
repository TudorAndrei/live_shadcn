// The delta hook.
//
// One job: put a token in the DOM without the server rendering anything.
//
// A LiveView that appends a token to an assign re-renders on every token. At
// twenty tokens a second and a conversation of any length, that is the whole
// cost of streaming. So the server pushes the token instead, and this hook
// writes it. `LiveAiElements.Stream.reduce/2` returns the identical state term
// for a delta, so `assign/3` marks nothing changed and no render runs.
//
// The hook is declared once, on the element that contains the parts:
//
//   <div id="conversation" phx-hook="LiveAiElements.Delta" phx-update="stream">
//
// and reads three attributes on what is inside it:
//
//   data-lae-part    on a part, carrying the part id the server addresses
//   data-lae-stream  on a part, present only while its text is still arriving
//   data-lae-text    on the descendant the text is written into
//
// None of them is read by a shadcn class string.
//
// ── While a part streams, this hook owns its text ──
//
// The server renders a streaming part's text as empty and fills it in one step
// when the part completes. So the sink's content is exactly what arrived here,
// and nothing has to be measured, diffed, or appended to.
//
// That is what makes `updated()` correct. LiveView replaces a part's node
// whenever anything about it changes — a tool moving from pending to running,
// for instance — and the replacement carries the server's empty text. Rewriting
// the buffer restores what a reader had already read.
//
// A part that has lost `data-lae-stream` is finished, and the text the server
// rendered is the authoritative one. The buffer is dropped rather than written
// back over it.

const PART = "data-lae-part";
const STREAM = "data-lae-stream";
const TEXT = "data-lae-text";

export const DELTA_EVENT = "live_ai_elements:delta";

export const Delta = {
  mounted() {
    this.buffers = new Map();

    this.handleEvent(DELTA_EVENT, ({ id, chunk }) => {
      if (!id || !chunk) return;

      const buffer = (this.buffers.get(id) || "") + chunk;
      this.buffers.set(id, buffer);
      this.write(id, buffer);
    });
  },

  updated() {
    for (const [id, buffer] of this.buffers) {
      const part = this.part(id);

      if (!part || !part.hasAttribute(STREAM)) {
        this.buffers.delete(id);
      } else {
        this.write(id, buffer);
      }
    }
  },

  destroyed() {
    this.buffers?.clear();
  },

  part(id) {
    return this.el.querySelector(`[${PART}="${CSS.escape(id)}"]`);
  },

  write(id, buffer) {
    const part = this.part(id);
    if (!part) return;

    const sink = part.matches(`[${TEXT}]`) ? part : part.querySelector(`[${TEXT}]`);
    if (sink) sink.textContent = buffer;
  },
};
