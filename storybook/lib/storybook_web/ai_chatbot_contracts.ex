defmodule StorybookWeb.AiChatbotContracts do
  @moduledoc "Examples of AI components with application-owned state."

  use Phoenix.LiveComponent

  alias LiveAiElements.Components.{
    Checkpoint,
    Context,
    Message,
    ModelSelector,
    PromptInput,
    Queue,
    Suggestion
  }

  alias LiveShadcn.UI.{Command, Dialog, HoverCard}
  alias Phoenix.LiveView.JS

  attr :component, :string, required: true

  def render_example(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id="ai-chatbot-contract" component={@component} />
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       restored: false,
       saved: false,
       branch: 0,
       selected_model: "Atlas",
       completed: false,
       removed: false,
       prompt: "",
       prompt_files: [],
       prompt_error: nil,
       prompt_submission: nil,
       prompt_stopped: false,
       actions: 0
     )}
  end

  @impl true
  def handle_event("restore", _params, socket) do
    {:noreply, assign(socket, restored: true, actions: socket.assigns.actions + 1)}
  end

  def handle_event("save", _params, socket) do
    {:noreply, assign(socket, saved: true)}
  end

  def handle_event("branch", %{"direction" => direction}, socket) do
    offset = if direction == "next", do: 1, else: -1
    {:noreply, assign(socket, branch: Integer.mod(socket.assigns.branch + offset, 2))}
  end

  def handle_event("select-model", %{"model" => model}, socket)
      when model in ["Atlas", "Orion"] do
    {:noreply, assign(socket, selected_model: model, actions: socket.assigns.actions + 1)}
  end

  def handle_event("complete", _params, socket) do
    {:noreply, assign(socket, completed: !socket.assigns.completed)}
  end

  def handle_event("remove", _params, socket) do
    {:noreply, assign(socket, removed: true)}
  end

  def handle_event("suggest", %{"suggestion" => suggestion}, socket) do
    {:noreply, assign(socket, prompt: suggestion, actions: socket.assigns.actions + 1)}
  end

  def handle_event("prompt-stop", _params, socket) do
    {:noreply, assign(socket, prompt_stopped: true)}
  end

  def handle_event("prompt-files", %{"files" => files}, socket) do
    {:noreply, assign(socket, prompt_files: files)}
  end

  def handle_event("prompt-error", %{"message" => message}, socket) do
    {:noreply, assign(socket, prompt_error: message)}
  end

  def handle_event("prompt-submit", %{"text" => "retry"}, socket) do
    {:reply, %{ok: false}, assign(socket, prompt_error: "Please retry the submission.")}
  end

  def handle_event("prompt-submit", message, socket) do
    {:reply, %{ok: true}, assign(socket, prompt_submission: message, prompt_error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="chatbot-contract" class="max-w-md space-y-4" data-actions={@actions}>
      <Checkpoint.checkpoint :if={@component == "checkpoint"}>
        <Checkpoint.checkpoint_trigger
          id="restore-checkpoint"
          tooltip="Restore this saved conversation"
          phx-click="restore"
          phx-target={@myself}
          disabled={@restored}
        >
          <Checkpoint.checkpoint_icon /> Restore checkpoint
        </Checkpoint.checkpoint_trigger>
      </Checkpoint.checkpoint>
      <p :if={@component == "checkpoint"} role="status">
        {if @restored, do: "Conversation restored", else: "Conversation changed"}
      </p>

      <HoverCard.hover_card :if={@component == "context"} id="context-usage" delay={0} close_delay={0}>
        <:trigger>Context usage</:trigger>
        <Context.context_content_header display_pct="25%" used="32K" total="128K" value="25" />
        <Context.context_content_body>
          <Context.context_input_usage
            id="context-input"
            input_tokens={31_000}
            input_cost_text="$0.03"
          />
          <Context.context_output_usage
            id="context-output"
            output_tokens={1_000}
            output_cost_text="$0.01"
          />
          <Context.context_reasoning_usage id="context-reasoning" reasoning_tokens={250} />
          <Context.context_cache_usage id="context-cache" cache_tokens={999_500_000} />
        </Context.context_content_body>
        <Context.context_content_footer total_cost="$0.04" />
      </HoverCard.hover_card>

      <Message.message :if={@component == "ai_elements-message"} from="assistant">
        <Message.message_content>
          <Message.message_branch>
            <Message.message_branch_content
              children_array={["First answer", "Second answer"]}
              current_branch={@branch}
            />
            <Message.message_branch_selector total_branches={2}>
              <Message.message_branch_previous
                total_branches={2}
                phx-click="branch"
                phx-value-direction="previous"
                phx-target={@myself}
              />
              <Message.message_branch_page current_branch={@branch} total_branches={2} />
              <Message.message_branch_next
                total_branches={2}
                phx-click="branch"
                phx-value-direction="next"
                phx-target={@myself}
              />
            </Message.message_branch_selector>
          </Message.message_branch>
          <Message.message_response content="Read the **selected answer**." />
          <Message.message_actions>
            <Message.message_action
              id="save-answer"
              label="Save answer"
              tooltip="Save this answer"
              phx-click="save"
              phx-target={@myself}
            >
              <LiveShadcn.Icon.icon name="bookmark" />
            </Message.message_action>
          </Message.message_actions>
          <p :if={@saved} role="status">Answer saved</p>
        </Message.message_content>
      </Message.message>

      <div :if={@component == "model-selector"}>
        <Dialog.dialog id="choose-model">
          <:trigger>
            <ModelSelector.model_selector_name>{@selected_model}</ModelSelector.model_selector_name>
          </:trigger>
          <:title>Select a model</:title>
          <:description>Choose the model for your next message.</:description>
          <Command.command id="models-command">
            <Command.command_input
              controls="models-list"
              aria-label="Search models"
              placeholder="Search models"
            />
            <Command.command_list id="models-list" label="Models">
              <Command.command_empty>No models found.</Command.command_empty>
              <Command.command_item
                :for={{model, provider} <- [{"Atlas", "openai"}, {"Orion", "anthropic"}]}
                value={model}
                phx-click={
                  JS.push("select-model", target: @myself, value: %{model: model})
                  |> LiveBase.Dialog.close("choose-model")
                }
              >
                <ModelSelector.model_selector_logo_group>
                  <ModelSelector.model_selector_logo provider={provider} />
                </ModelSelector.model_selector_logo_group>
                <ModelSelector.model_selector_name>{model}</ModelSelector.model_selector_name>
              </Command.command_item>
            </Command.command_list>
          </Command.command>
        </Dialog.dialog>
        <p role="status">Selected model: {@selected_model}</p>
      </div>

      <Queue.queue :if={@component == "queue"}>
        <Queue.queue_section_label count={if @removed, do: 1, else: 2} label=" tasks" />
        <Queue.queue_list>
          <Queue.queue_item id="queue-review">
            <Queue.queue_item_indicator completed={@completed} />
            <Queue.queue_item_content completed={@completed}>
              Review the response
            </Queue.queue_item_content>
            <Queue.queue_item_description completed={@completed}>
              Check the cited sources.
            </Queue.queue_item_description>
            <Queue.queue_item_actions>
              <Queue.queue_item_action
                phx-click="complete"
                phx-target={@myself}
                aria-label="Toggle completion"
              >
                <LiveShadcn.Icon.icon name="check" />
              </Queue.queue_item_action>
            </Queue.queue_item_actions>
          </Queue.queue_item>
          <Queue.queue_item :if={!@removed} id="queue-draft">
            <Queue.queue_item_content>Draft the report</Queue.queue_item_content>
            <Queue.queue_item_attachment>
              <Queue.queue_item_file>notes.txt</Queue.queue_item_file>
            </Queue.queue_item_attachment>
            <Queue.queue_item_actions>
              <Queue.queue_item_action
                phx-click="remove"
                phx-target={@myself}
                aria-label="Remove draft"
              >
                <LiveShadcn.Icon.icon name="x" />
              </Queue.queue_item_action>
            </Queue.queue_item_actions>
          </Queue.queue_item>
        </Queue.queue_list>
      </Queue.queue>

      <div :if={@component == "prompt-input"}>
        <PromptInput.prompt_input_provider initial_input="Review these files">
          <PromptInput.prompt_input
            id="files-form"
            accept="text/plain"
            multiple
            max_files={2}
            max_file_size={16}
            global_drop
            sync_hidden_input
            on_files_change="prompt-files"
            on_error="prompt-error"
            on_submit="prompt-submit"
            phx-target={@myself}
          >
            <PromptInput.prompt_input_textarea id="files-prompt" aria-label="Message" />
            <PromptInput.prompt_input_footer>
              <button
                type="button"
                phx-click={JS.dispatch("click", to: "#files-form [data-ai-prompt-files]")}
              >
                Attach files
              </button>
              <PromptInput.prompt_input_submit />
            </PromptInput.prompt_input_footer>
          </PromptInput.prompt_input>
        </PromptInput.prompt_input_provider>
        <PromptInput.prompt_input_submit
          status="streaming"
          on_stop="prompt-stop"
          phx-target={@myself}
        />
        <p :if={@prompt_stopped} role="status">Generation stopped</p>
        <ul aria-label="Attachments">
          <li :for={file <- @prompt_files}>
            {file["filename"]}
            <button
              type="button"
              phx-click={
                JS.dispatch("live-ai:prompt-remove", to: "#files-form", detail: %{id: file["id"]})
              }
            >Remove {file["filename"]}</button>
          </li>
        </ul>
        <p :if={@prompt_error} role="alert">{@prompt_error}</p>
        <div :if={@prompt_submission} role="status">
          Submitted: {@prompt_submission["text"]}
          <code id="submitted-files">{Jason.encode!(@prompt_submission["files"])}</code>
        </div>
      </div>

      <div :if={@component == "suggestion"}>
        <Suggestion.suggestions>
          <Suggestion.suggestion
            suggestion="Explain the result"
            phx-click="suggest"
            phx-value-suggestion="Explain the result"
            phx-target={@myself}
          />
          <Suggestion.suggestion
            suggestion="Show the sources"
            phx-click="suggest"
            phx-value-suggestion="Show the sources"
            phx-target={@myself}
          >
            Sources
          </Suggestion.suggestion>
          <Suggestion.suggestion
            suggestion="Unavailable"
            disabled
            phx-click="suggest"
            phx-target={@myself}
          />
        </Suggestion.suggestions>
        <label for="suggested-prompt">Prompt</label>
        <textarea id="suggested-prompt" readonly>{@prompt}</textarea>
      </div>
    </div>
    """
  end
end
