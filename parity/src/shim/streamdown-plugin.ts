// A Streamdown plugin, with the renderer shimmed away.
//
// `reasoning.tsx` and `message.tsx` pass four of these to `<Streamdown>`:
// `cjk`, `code`, `math` and `mermaid`. The shim renders the text as text, so a
// plugin has nothing to extend — and each name has to resolve, because an
// import that does not is a page that does not render at all.
export const cjk = {};
export const code = {};
export const math = {};
export const mermaid = {};
