import {
  OpenIn,
  OpenInChatGPT,
  OpenInClaude,
} from "@upstream/ai_elements/open-in-chat";

// Ported from `StorybookWeb.Examples.open_in_chat_default/1`.
//
// Upstream puts the query in a context that the root owns and each provider
// reads it back; here each link is given it, which is the answer every React
// context in this registry gets. The root is present so the React side has a
// context to read — it draws no element of its own.
//
// `<DropdownMenuItem asChild><a href={…}>` is one element and it is the link:
// a logo, a title, an external-link icon and a query string. The generated
// component draws that link, and a caller composes `<.dropdown_menu>` around
// it — which is what upstream's own menu is.
export default function OpenInChatDefault() {
  return (
    <div className="w-fit">
      <OpenIn query="How does the fold work?">
        <OpenInChatGPT />
        <OpenInClaude />
      </OpenIn>
    </div>
  );
}
