defmodule LiveAiElements.Components.PromptInput do
  @moduledoc """
  Prompt input. Built on `shadcn/input-group`, `shadcn/textarea`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.

  The textarea hook manages local attachments. `on_files_change` and `on_error`
  name optional LiveView events. `on_submit` receives `%{text: text, files: files}`;
  each file has `type`, `filename`, `mediaType`, and a data URL. A reply with
  `ok: false` keeps the draft for a retry. Other replies clear the submitted draft.
  Use `phx-target` on the form to send these events to a LiveComponent.

  The form also emits `live-ai:prompt-files-change` and `live-ai:prompt-error`
  DOM events. Dispatch `live-ai:prompt-remove` with an attachment `id`, or
  `live-ai:prompt-clear`, on the form to change its attachment list.

  As in the pinned upstream, `sync_hidden_input` only clears the file picker
  when the attachment list becomes empty. It does not put files in a native
  form post. Use `on_submit` to receive attachment data.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/inputGroupAddonVariants/variant/align/block-end" =>
      "cn-input-group-addon-align-block-end order-last w-full justify-start",
    "cva/inputGroupAddonVariants/variant/align/block-start" =>
      "cn-input-group-addon-align-block-start order-first w-full justify-start",
    "cva/inputGroupAddonVariants/variant/align/inline-end" =>
      "cn-input-group-addon-align-inline-end order-last",
    "cva/inputGroupAddonVariants/variant/align/inline-start" =>
      "cn-input-group-addon-align-inline-start order-first",
    "cva/inputGroupButtonVariants/base" => "cn-input-group-button flex items-center shadow-none",
    "cva/inputGroupButtonVariants/variant/size/icon-sm" => "cn-input-group-button-size-icon-sm",
    "cva/inputGroupButtonVariants/variant/size/icon-xs" => "cn-input-group-button-size-icon-xs",
    "cva/inputGroupButtonVariants/variant/size/sm" => "cn-input-group-button-size-sm",
    "cva/inputGroupButtonVariants/variant/size/xs" => "cn-input-group-button-size-xs",
    "jsx/PromptInput/class/0" => "hidden",
    "jsx/PromptInput/class/1" => "w-full",
    "jsx/PromptInputActionMenuTrigger/class/0" => "size-4",
    "jsx/PromptInputBody/class/0" => "contents",
    "jsx/PromptInputTabBody/class/0" => "space-y-1",
    "jsx/PromptInputTabItem/class/0" =>
      "flex items-center gap-2 px-3 py-2 text-xs hover:bg-accent",
    "jsx/PromptInputTabLabel/class/0" => "mb-2 px-3 font-medium text-muted-foreground text-xs",
    "jsx/PromptInputTools/class/0" => "flex min-w-0 items-center gap-1",
    "port/class/0" =>
      "cn-input-group-addon flex cursor-text items-center justify-center select-none justify-between gap-1",
    "port/class/1" =>
      "cn-input-group-addon flex cursor-text items-center justify-center select-none order-first flex-wrap gap-1",
    "port/class/2" =>
      "cn-textarea flex field-sizing-content min-h-16 w-full outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50 cn-input-group-textarea flex-1 resize-none field-sizing-content max-h-48 min-h-16",
    "port/class/3" =>
      "group/input-group cn-input-group relative flex w-full min-w-0 items-center outline-none has-[>textarea]:h-auto overflow-hidden"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @variant_classes (for {"cva/" <> path, value} <- @upstream_facts,
                        [table, "variant", group, choice] <- [String.split(path, "/")],
                        reduce: %{} do
                      variants ->
                        put_in(
                          variants,
                          [
                            Access.key(table, %{}),
                            Access.key(group, %{}),
                            Access.key(choice, nil)
                          ],
                          value
                        )
                    end)

  alias LiveBase.FormControl

  @doc "The `prompt_input_provider` part."
  attr(:initial_input, :string, default: "")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_provider(assigns) do
    ~H"""
    <div data-ai-prompt-provider data-initial-input={@initial_input} class={["contents", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `prompt_input` part."
  attr(:accept, :string, default: nil)
  attr(:attachments, :string, default: nil)
  attr(:global_drop, :boolean, default: false)
  attr(:inner, :string, default: nil)
  attr(:max_file_size, :integer, default: nil)
  attr(:max_files, :integer, default: nil)
  attr(:multiple, :boolean, default: nil)
  attr(:sync_hidden_input, :boolean, default: false)
  attr(:text_input, :string, default: nil)
  attr(:with_referenced_sources, :string, default: nil)
  attr(:on_files_change, :string, default: nil)
  attr(:on_error, :string, default: nil)
  attr(:on_submit, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: ["data-slot", "action", "method", "enctype", "novalidate", "target"]
  )

  slot(:inner_block)

  def prompt_input(assigns) do
    ~H"""
    <form
      class={[upstream_fact("jsx/PromptInput/class/1"), @class]}
      data-ai-prompt-form
      data-max-files={@max_files}
      data-max-file-size={@max_file_size}
      data-global-drop={to_string(@global_drop)}
      data-sync-hidden-input={to_string(@sync_hidden_input)}
      data-files-change-event={@on_files_change}
      data-error-event={@on_error}
      data-submit-event={@on_submit}
      {@rest}
    >
      <input
        data-ai-prompt-files
        accept={@accept}
        aria-label="Upload files"
        multiple={@multiple}
        title="Upload files"
        type="file"
        class={upstream_fact("jsx/PromptInput/class/0")}
      />
      <div
        data-slot={@rest[:"data-slot"] || "input-group"}
        role="group"
        class={[Shadcn.input_group_class(), "overflow-hidden"]}
      >
        {render_slot(@inner_block)}
      </div>
    </form>
    """
  end

  @doc "The `prompt_input_body` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_body(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PromptInputBody/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The `input-group-control` part.

      <.prompt_input_textarea id="prompt" field={@form[:email]} />

  A `:field` fills in the id, the name, the value, and the errors. Errors
  show only once the form has been used: an untouched form is not a form
  with mistakes in it.
  """
  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field. Fills in id, name, value and errors."
  )

  attr(:id, :string, required: true, doc: "The browser hook needs a stable id.")
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil, doc: "The field's value.")
  attr(:errors, :list, default: [])
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:files, :string, default: nil)
  attr(:placeholder, :string, default: "What would you like to know?")
  attr(:text_input, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: [
      "data-slot",
      "name",
      "placeholder",
      "rows",
      "cols",
      "readonly",
      "wrap",
      "disabled",
      "required"
    ]
  )

  slot(:inner_block)

  def prompt_input_textarea(assigns) do
    assigns = FormControl.from_field(assigns)

    ~H"""
    <textarea
      phx-no-format
      id={@id}
      name={@name || "message"}
      disabled={@disabled}
      readonly={@readonly}
      required={@required}
      aria-invalid={if @errors != [], do: "true"}
      data-explicit-value={if !is_nil(@value), do: "true"}
      data-input-value={@value}
      phx-hook={hook()}
      data-slot={@rest[:"data-slot"] || "input-group-control"}
      placeholder={@placeholder}
      class={[
        Shadcn.textarea_class(),
        "flex-1 resize-none !rounded-none !border-0 bg-transparent !py-3 !shadow-none focus-visible:!ring-0 dark:bg-transparent field-sizing-content max-h-48 min-h-16",
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{@value || render_slot(@inner_block)}</textarea>
    """
  end

  @doc "The `input-group-addon` part."
  attr(:align, :string,
    default: "block-end",
    values:
      @variant_classes
      |> get_in(["inputGroupAddonVariants", "align"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_header(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "input-group-addon"}
      role="group"
      data-align={@align}
      class={[
        Shadcn.input_group_addon_class(@align),
        "order-first flex-wrap !gap-1",
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `input-group-addon` part."
  attr(:align, :string,
    default: "block-end",
    values:
      @variant_classes
      |> get_in(["inputGroupAddonVariants", "align"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_footer(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "input-group-addon"}
      role="group"
      data-align={@align}
      class={[
        Shadcn.input_group_addon_class(@align),
        "!justify-between !gap-1",
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `prompt_input_tools` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_tools(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PromptInputTools/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `prompt_input_submit` part."
  attr(:icon, :string, default: nil)
  attr(:is_generating, :boolean, default: false)
  attr(:on_stop, :any, default: nil, doc: "A caller click command while submitted or streaming.")

  attr(:size, :string,
    default: "icon-sm",
    values:
      @variant_classes
      |> get_in(["inputGroupButtonVariants", "size"])
      |> Map.keys()
      |> Enum.sort()
  )

  attr(:status, :string, default: nil)
  attr(:type, :string, default: "submit")
  attr(:variant, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def prompt_input_submit(assigns) do
    generating = assigns.is_generating || assigns.status in ["submitted", "streaming"]

    icon =
      assigns.icon ||
        case assigns.status do
          "submitted" -> "loader-circle"
          "streaming" -> "square"
          "error" -> "x"
          _ -> "corner-down-left"
        end

    assigns = assign(assigns, generating: generating, status_icon: icon)

    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "button"}
      type={if @generating && @on_stop, do: "button", else: @type}
      data-size={@size}
      aria-label={if(@generating, do: "Stop", else: "Submit")}
      phx-click={if @generating && @on_stop, do: @on_stop, else: @rest[:"phx-click"]}
      class={[
        Shadcn.button_class(@size, @variant),
        "text-sm !shadow-none flex min-w-0 gap-2 items-center !size-8 !p-0 has-[>svg]:p-0",
        @class
      ]}
      {Map.drop(@rest, [:"data-slot", :"phx-click"])}
    >
      <%= if @inner_block == [] do %>
        <LiveShadcn.Icon.icon
          name={@status_icon}
          class={[upstream_fact("jsx/PromptInputActionMenuTrigger/class/0"), if(@status == "submitted", do: "animate-spin")]}
        />
      <% end %>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `prompt_input_tabs_list` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_tabs_list(assigns) do
    ~H"""
    <div class={[@class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `prompt_input_tab` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_tab(assigns) do
    ~H"""
    <div class={[@class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `prompt_input_tab_label` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_tab_label(assigns) do
    ~H"""
    <h3 class={[upstream_fact("jsx/PromptInputTabLabel/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc "The `prompt_input_tab_body` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_tab_body(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PromptInputTabBody/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `prompt_input_tab_item` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def prompt_input_tab_item(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/PromptInputTabItem/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The client hook name the prompt form declares in `phx-hook`."
  def hook, do: "LiveAiElements.Components.PromptInput.PromptInput"

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook prompt_input.js#PromptInput --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PromptInput">
      const PromptInput = {
        mounted() {
          this.form = this.el.form;
          this.files = [];
          this.composing = false;
          this.submitting = false;
          const provider = this.el.closest("[data-ai-prompt-provider]");
          if (provider && !this.el.dataset.explicitValue) this.el.value = provider.dataset.initialInput || "";
          this.renderedValue = this.el.dataset.inputValue;
          this.el.setAttribute("data-ai-prompt-draft", "");
          this.onCompositionStart = () => {
            this.composing = true;
          };
          this.onCompositionEnd = () => {
            this.composing = false;
          };
          this.onKeyDown = (event) => {
            if (event.defaultPrevented || this.composing || event.isComposing) return;
            if (event.key === "Backspace" && this.el.value === "" && this.files.length) {
              event.preventDefault();
              this.remove(this.files.at(-1).id);
              return;
            }
            if (event.key !== "Enter" || event.shiftKey) return;
            if ((this.form?.querySelector("button[type=\"submit\"]"))?.disabled) return;
            event.preventDefault();
            this.form?.requestSubmit();
          };
          this.onChange = (event) => {
            if (!event.target.matches("[data-ai-prompt-files]")) return;
            this.add(event.target.files);
            event.target.value = "";
          };
          this.onPaste = (event) => {
            const files = [...event.clipboardData?.items || []].filter((item) => item.kind === "file").map((item) => item.getAsFile()).filter(Boolean);
            if (files.length) {
              event.preventDefault();
              this.add(files);
            }
          };
          this.onDragOver = (event) => {
            if ([...event.dataTransfer?.types || []].includes("Files")) event.preventDefault();
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
          const renderedValue = this.el.dataset.inputValue;
          if (renderedValue !== this.renderedValue) this.el.value = renderedValue || "";
          else if (this.draftValue !== void 0) this.el.value = this.draftValue;
          this.renderedValue = renderedValue;
          this.draftValue = void 0;
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
          for (const file of sized.slice(0, capacity)) this.files.push({
            id: crypto.randomUUID(),
            file,
            url: URL.createObjectURL(file)
          });
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
          if (!this.files.length && this.form?.dataset.syncHiddenInput === "true" && this.picker()) this.picker().value = "";
          this.notify("files-change", { files: this.files.map(({ id, file, url }) => ({
            id,
            type: "file",
            filename: file.name,
            mediaType: file.type,
            url
          })) }, this.form?.dataset.filesChangeEvent);
        },
        error(code, message) {
          this.notify("error", {
            code,
            message
          }, this.form?.dataset.errorEvent);
        },
        notify(name, detail, serverEvent) {
          this.form?.dispatchEvent(new CustomEvent(`live-ai:prompt-${name}`, {
            detail,
            bubbles: true
          }));
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
              reader.onload = () => resolve({
                type: "file",
                filename: file.name,
                mediaType: file.type,
                url: reader.result
              });
              reader.onerror = () => reject(reader.error);
              reader.readAsDataURL(file);
            })));
            const response = (await this.pushEventTo(this.eventTarget(), this.form.dataset.submitEvent, {
              text,
              files
            })).find((result) => result.status === "fulfilled");
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
        }
      };
      export default PromptInput;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
