# live_ai_elements

Part of [live_shadcn](https://github.com/TudorAndrei/live_shadcn). See the
repository README for the design and the current status.

It requires `phoenix_live_view` 1.2 or later and `phoenix` 1.8 or later.
LiveView compiles colocated hooks only with Phoenix 1.8 or later.

## Hooks

The hooks are LiveView colocated hooks. When Mix compiles `live_ai_elements`,
LiveView writes them to `phoenix-colocated/live_ai_elements` in
`Mix.Project.build_path()`. Install `live_base` and its npm peers as the
`live_base` README shows. Put both `Mix.Project.build_path()` and
`assets/node_modules` in the esbuild `NODE_PATH`, and run `mix compile` before
esbuild.

Import the package for its document-level behavior, and register the hooks
with your LiveSocket, alongside the `live_base` hooks:

```js
import "live_base";
import "live_ai_elements";
import { hooks as liveBase } from "phoenix-colocated/live_base";
import { hooks as liveAiElements } from "phoenix-colocated/live_ai_elements";

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...liveBase, ...liveAiElements },
});
```

Markup gets each hook name from its module, as in
`phx-hook={LiveAiElements.Delta.hook()}`.

The hooks manifest includes the Persona hook, which imports `@rive-app/webgl2`.
Install that package in `assets/node_modules`, even when no page renders a
Persona:

```bash
cd assets
npm install --install-links ../deps/live_ai_elements @rive-app/webgl2@2.34.1
```

## Prompt input

Register the hooks as shown above. Compose a prompt form with a textarea. The
textarea needs a stable ID.

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
