# live_ai_elements

Part of [live_shadcn](https://github.com/TudorAndrei/live_shadcn). See the
repository README for the design and the current status.

## Hooks

The package's `hooks` export holds every hook. Register it with your
LiveSocket:

```js
import { hooks as liveBase } from "live_base";
import { hooks as liveAiElements } from "live_ai_elements";

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...liveBase, ...liveAiElements },
});
```

The `LiveAiElements.Persona` hook imports `@rive-app/webgl2`, so this entry
needs that package. An application that does not render a Persona can import
each hook it uses from its own subpath. Its bundler then does not resolve Rive:

```js
import { Delta } from "live_ai_elements/delta";
import { installAttachmentRemove } from "live_ai_elements/attachment_remove";

installAttachmentRemove();

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...liveBase, "LiveAiElements.Delta": Delta },
});
```

Each hook module has a subpath with its file name: `attachment_remove`,
`delta`, `file_tree`, `mic_selector`, `persona`, `prompt_input`, `question`,
`speech_input`, `terminal`, `transcription`, and `web_preview`. The root entry
calls `installAttachmentRemove()` for you; a subpath import does not.

## Prompt input

Register the `LiveAiElements.PromptInput` hook through the package's `hooks`
export. Compose a prompt form with a textarea. The textarea needs a stable ID.

```heex
<PromptInput.prompt_input_provider initial_input="Review these files">
  <PromptInput.prompt_input
    id="chat-prompt"
    accept="image/*,text/plain"
    multiple
    max_files={3}
    max_file_size={5_000_000}
    on_files_change="prompt_files"
    on_error="prompt_error"
    on_submit="send_message"
  >
    <PromptInput.prompt_input_textarea id="chat-message" />
    <PromptInput.prompt_input_footer>
      <PromptInput.prompt_input_submit />
    </PromptInput.prompt_input_footer>
  </PromptInput.prompt_input>
</PromptInput.prompt_input_provider>
```

The form accepts file picker changes, file pastes, and drops inside the form.
Set `global_drop` to accept drops anywhere in the document. `accept`,
`max_file_size`, and `max_files` also apply to pasted and dropped files.

`on_files_change` receives `%{"files" => files}`. Each file has an `id`,
`filename`, `mediaType`, and a local preview `url`. Use these values to render
attachments. Dispatch `live-ai:prompt-remove` on the form with `%{id: file_id}`
to remove an attachment. Dispatch `live-ai:prompt-clear` to clear all attachments.
Backspace also removes the last attachment when the textarea is empty.

`on_error` receives a `code` and a `message`. `on_submit` receives `text` and
`files`. Submitted files contain data URLs, so the caller can read their content.
Reply with `%{ok: false}` to keep the draft after a failed submission. Other
replies clear the submitted text and files. Text entered during submission stays
in the textarea. Set `phx-target={@myself}` on the form when a LiveComponent owns
these events. Standard `phx-submit` remains available if `on_submit` is omitted.

The form also emits the DOM events `live-ai:prompt-files-change` and
`live-ai:prompt-error` for browser callers. As in the pinned upstream,
`sync_hidden_input` only resets the file picker when the attachment list is
empty. It does not serialize attachments into a native form post.

Use `status="submitted"` or `status="streaming"` with `on_stop="stop_message"`
on the submit component to show a Stop action. A Stop action sends its caller
command without submitting a new message.
