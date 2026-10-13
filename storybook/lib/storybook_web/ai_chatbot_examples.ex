defmodule StorybookWeb.AiChatbotExamples do
  @moduledoc "Ports of the pinned AI chatbot example variants."
  use Phoenix.LiveComponent

  alias LiveAiElements.Components.{
    Attachments,
    CodeBlock,
    ModelSelector,
    PromptInput,
    Queue,
    Shimmer,
    Sources,
    Suggestion,
    Tool
  }

  alias LiveShadcn.UI.{Command, Dialog, HoverCard, Select, Tooltip}
  alias Phoenix.LiveView.JS

  @variants %{
    "prompt-input" => ~w(cursor tooltip),
    "queue" => ~w(prompt-input),
    "shimmer" => ~w(duration elements),
    "sources" => ~w(custom),
    "suggestion" => ~w(input),
    "tool" => ~w(input-available input-streaming output-available output-error)
  }

  @models [
    %{
      id: "gpt-4o",
      name: "GPT-4o",
      provider: "openai",
      chef: "OpenAI",
      providers: ~w(openai azure)
    },
    %{
      id: "gpt-4o-mini",
      name: "GPT-4o Mini",
      provider: "openai",
      chef: "OpenAI",
      providers: ~w(openai azure)
    },
    %{
      id: "claude-opus-4-20250514",
      name: "Claude 4 Opus",
      provider: "anthropic",
      chef: "Anthropic",
      providers: ~w(anthropic azure google amazon-bedrock)
    },
    %{
      id: "claude-sonnet-4-20250514",
      name: "Claude 4 Sonnet",
      provider: "anthropic",
      chef: "Anthropic",
      providers: ~w(anthropic azure google amazon-bedrock)
    },
    %{
      id: "gemini-2.0-flash-exp",
      name: "Gemini 2.0 Flash",
      provider: "google",
      chef: "Google",
      providers: ~w(google)
    }
  ]
  @sources [
    %{
      id: "1",
      type: "source-document",
      mediaType: "text/plain",
      filename: "packages/elements/src",
      title: "prompt-input.tsx"
    },
    %{
      id: "2",
      type: "source-document",
      mediaType: "text/plain",
      filename: "apps/test/app/examples",
      title: "queue.tsx"
    },
    %{
      id: "3",
      type: "source-document",
      mediaType: "text/plain",
      filename: "packages/elements/src",
      title: "queue.tsx"
    }
  ]
  @suggestions [
    "What are the latest trends in AI?",
    "How does machine learning work?",
    "Explain quantum computing",
    "Best practices for React development",
    "Tell me about TypeScript benefits",
    "How to optimize database queries?",
    "What is the difference between SQL and NoSQL?",
    "Explain cloud computing basics"
  ]

  def all(component) do
    for id <- Map.get(@variants, component, []) do
      kind = "#{component}/#{id}"

      %{
        id: id,
        title: String.replace(id, "-", " "),
        description: "The pinned AI Elements #{id} example.",
        render: fn assigns -> example(assign(assigns, :kind, kind)) end,
        snapshot_component: __MODULE__,
        snapshot_assigns: [id: variant_id(kind), kind: kind]
      }
    end
  end

  attr :kind, :string, required: true

  def example(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id={variant_id(@kind)} kind={@kind} />
    """
  end

  defp variant_id(kind), do: "ai-variant-" <> String.replace(kind, "/", "-")

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       text: "",
       files: [],
       refs: [],
       status: "ready",
       generation: 0,
       model: hd(@models),
       last_submission: nil,
       todos: [
         %{
           id: "todo-1",
           title: "Write project documentation",
           description: "Complete the README and API docs",
           completed: true
         },
         %{id: "todo-2", title: "Implement authentication", description: nil, completed: false},
         %{
           id: "todo-3",
           title: "Fix bug #42",
           description: "Resolve crash on settings page",
           completed: false
         },
         %{
           id: "todo-4",
           title: "Refactor queue logic",
           description: "Unify queue and todo state management",
           completed: false
         },
         %{
           id: "todo-5",
           title: "Add unit tests",
           description: "Increase test coverage for hooks",
           completed: false
         }
       ]
     )}
  end

  @impl true
  def update(%{phase: phase, generation: generation}, socket) do
    {:ok,
     if(generation == socket.assigns.generation, do: assign(socket, status: phase), else: socket)}
  end

  def update(assigns, socket), do: {:ok, assign(socket, assigns)}

  @impl true
  def handle_event("files", %{"files" => files}, socket),
    do: {:noreply, assign(socket, files: files)}

  def handle_event("suggestion", %{"suggestion" => value}, socket),
    do: {:noreply, assign(socket, text: value)}

  def handle_event("remove-todo", %{"id" => id}, socket),
    do: {:noreply, assign(socket, todos: Enum.reject(socket.assigns.todos, &(&1.id == id)))}

  def handle_event("model", %{"id" => id}, socket),
    do:
      {:noreply,
       assign(socket, model: Enum.find(@models, &(&1.id == id)) || socket.assigns.model)}

  def handle_event("add-source", %{"id" => id}, socket) do
    source = Enum.find(@sources, &(&1.id == id))

    refs =
      if source && !Enum.any?(socket.assigns.refs, &(&1.id == id)),
        do: socket.assigns.refs ++ [source],
        else: socket.assigns.refs

    {:noreply, assign(socket, refs: refs)}
  end

  def handle_event("remove-source", %{"id" => id}, socket),
    do: {:noreply, assign(socket, refs: Enum.reject(socket.assigns.refs, &(&1.id == id)))}

  def handle_event("stop", _params, socket),
    do: {:noreply, assign(socket, status: "ready", generation: socket.assigns.generation + 1)}

  def handle_event("submit", _message, %{assigns: %{status: status}} = socket)
      when status in ["submitted", "streaming"],
      do:
        {:reply, %{ok: false},
         assign(socket, status: "ready", generation: socket.assigns.generation + 1)}

  def handle_event("submit", %{"text" => "", "files" => []}, socket),
    do: {:reply, %{ok: false}, socket}

  def handle_event("submit", message, socket) do
    if socket.assigns.kind in ["prompt-input/cursor", "queue/prompt-input"] do
      generation = socket.assigns.generation + 1

      Phoenix.LiveView.send_update_after(
        __MODULE__,
        %{id: socket.assigns.id, phase: "streaming", generation: generation},
        200
      )

      Phoenix.LiveView.send_update_after(
        __MODULE__,
        %{id: socket.assigns.id, phase: "ready", generation: generation},
        2000
      )

      {:reply, %{ok: true},
       assign(socket,
         status: "submitted",
         generation: generation,
         text: "",
         refs: [],
         last_submission: message
       )}
    else
      {:reply, %{ok: true}, assign(socket, text: "", last_submission: message)}
    end
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, models: @models, sample_sources: @sources, suggestions: @suggestions)

    ~H"""
    <div id={@id} class="w-full max-w-2xl space-y-4">
      <.shimmer_duration :if={@kind == "shimmer/duration"} />
      <.shimmer_elements :if={@kind == "shimmer/elements"} />
      <.custom_sources :if={@kind == "sources/custom"} />
      <.tool_example
        :if={String.starts_with?(@kind, "tool/")}
        id={"#{@id}-tool"}
        state={String.replace_prefix(@kind, "tool/", "")}
      />

      <div
        :if={
          @kind in [
            "prompt-input/cursor",
            "prompt-input/tooltip",
            "queue/prompt-input",
            "suggestion/input"
          ]
        }
        class="grid gap-4"
      >
        <Suggestion.suggestions :if={@kind == "suggestion/input"}>
          <Suggestion.suggestion
            :for={suggestion <- @suggestions}
            suggestion={suggestion}
            phx-click="suggestion"
            phx-value-suggestion={suggestion}
            phx-target={@myself}
          />
        </Suggestion.suggestions>
        <Queue.queue
          :if={@kind == "queue/prompt-input"}
          class="mx-auto max-h-[150px] w-[95%] overflow-y-auto rounded-b-none border-b-0"
        >
          <ul>
            <Queue.queue_item :for={todo <- @todos} id={todo.id}>
              <div class="flex gap-2">
                <Queue.queue_item_indicator completed={todo.completed} />
                <Queue.queue_item_content completed={todo.completed}>
                  {todo.title}
                </Queue.queue_item_content>
                <Queue.queue_item_actions>
                  <Queue.queue_item_action
                    aria-label={"Remove " <> todo.title}
                    phx-click="remove-todo"
                    phx-value-id={todo.id}
                    phx-target={@myself}
                  >
                    <LiveShadcn.Icon.icon name="trash-2" />
                  </Queue.queue_item_action>
                </Queue.queue_item_actions>
              </div>
              <Queue.queue_item_description :if={todo.description} completed={todo.completed}>
                {todo.description}
              </Queue.queue_item_description>
            </Queue.queue_item>
          </ul>
        </Queue.queue>
        <PromptInput.prompt_input
          id={"#{@id}-prompt"}
          global_drop={@kind in ["prompt-input/cursor", "queue/prompt-input"]}
          multiple
          on_files_change="files"
          on_submit="submit"
          phx-target={@myself}
        >
          <PromptInput.prompt_input_header :if={@kind == "prompt-input/cursor" || @files != []}>
            <.cursor_context
              :if={@kind == "prompt-input/cursor"}
              refs={@refs}
              sample_sources={@sample_sources}
              target={@myself}
            />
            <Attachments.attachments id={"#{@id}-attachments"} variant="inline">
              <Attachments.attachment
                :for={file <- @files}
                data={file}
                variant="inline"
                on_remove={
                  JS.dispatch("live-ai:prompt-remove",
                    to: "##{@id}-prompt",
                    detail: %{id: file["id"]}
                  )
                }
              />
              <Attachments.attachment
                :for={source <- @refs}
                data={source}
                variant="inline"
                on_remove={JS.push("remove-source", target: @myself, value: %{id: source.id})}
              />
            </Attachments.attachments>
          </PromptInput.prompt_input_header>
          <PromptInput.prompt_input_textarea
            id={"#{@id}-message"}
            value={@text}
            aria-label="Message"
            placeholder={
              if @kind == "prompt-input/cursor",
                do: "Plan, search, build anything",
                else:
                  if(@kind == "suggestion/input",
                    do: "Ask me about anything...",
                    else: "What would you like to know?"
                  )
            }
          />
          <PromptInput.prompt_input_footer>
            <PromptInput.prompt_input_tools>
              <.tooltip_tools :if={@kind == "prompt-input/tooltip"} />
              <button
                :if={@kind in ["queue/prompt-input", "suggestion/input"]}
                type="button"
                aria-label="Attach files"
                phx-click={JS.dispatch("click", to: "##{@id}-prompt [data-ai-prompt-files]")}
              ><LiveShadcn.Icon.icon name="plus" /></button>
              <button :if={@kind == "suggestion/input"} type="button" aria-label="Voice input"><LiveShadcn.Icon.icon name="mic" /></button>
              <button :if={@kind in ["queue/prompt-input", "suggestion/input"]} type="button"><LiveShadcn.Icon.icon name="globe" />
              Search</button>
              <.model_picker
                :if={@kind in ["prompt-input/cursor", "queue/prompt-input"]}
                model={@model}
                models={@models}
                target={@myself}
              />
              <Select.select
                :if={@kind == "suggestion/input"}
                id="suggestion-model"
                name="model"
                value="gpt-4"
                aria-label="Model"
              >
                <:option value="gpt-4" label="GPT-4" />
                <:option value="gpt-3.5-turbo" label="GPT-3.5 Turbo" />
                <:option value="claude-2" label="Claude 2" />
                <:option value="claude-instant" label="Claude Instant" />
                <:option value="palm-2" label="PaLM 2" />
                <:option value="llama-2-70b" label="Llama 2 70B" />
                <:option value="llama-2-13b" label="Llama 2 13B" />
                <:option value="cohere-command" label="Command" />
                <:option value="mistral-7b" label="Mistral 7B" />
              </Select.select>
            </PromptInput.prompt_input_tools>
            <button
              :if={@kind == "prompt-input/cursor"}
              type="button"
              aria-label="Attach image"
              phx-click={JS.dispatch("click", to: "##{@id}-prompt [data-ai-prompt-files]")}
            ><LiveShadcn.Icon.icon name="image" /></button>
            <PromptInput.prompt_input_submit status={@status} on_stop="stop" phx-target={@myself} />
          </PromptInput.prompt_input_footer>
        </PromptInput.prompt_input>
        <p :if={@last_submission} role="status">Submitted: {@last_submission["text"]}</p>
      </div>
    </div>
    """
  end

  defp tooltip_tools(assigns) do
    ~H"""
    <Tooltip.tooltip
      id="prompt-attach-tooltip"
      trigger_label="Attach files"
      trigger_variant="ghost"
      trigger_size="icon-sm"
    >
      <:trigger><LiveShadcn.Icon.icon name="paperclip" /></:trigger>
      Attach files
    </Tooltip.tooltip>
    <Tooltip.tooltip
      id="prompt-search-tooltip"
      trigger_label="Search the web"
      trigger_variant="ghost"
      trigger_size="icon-sm"
    >
      <:trigger><LiveShadcn.Icon.icon name="globe" /></:trigger>
      Search the web <kbd>⌘K</kbd>
    </Tooltip.tooltip>
    <Tooltip.tooltip
      id="prompt-voice-tooltip"
      trigger_label="Voice input"
      trigger_variant="ghost"
      trigger_size="icon-sm"
      side="bottom"
    >
      <:trigger><LiveShadcn.Icon.icon name="mic" /></:trigger>
      Voice input <kbd>⌘M</kbd>
    </Tooltip.tooltip>
    """
  end

  defp model_picker(assigns) do
    ~H"""
    <Dialog.dialog id="variant-model">
      <:trigger>
        <ModelSelector.model_selector_logo provider={@model.provider} /><ModelSelector.model_selector_name>
          {@model.name}
        </ModelSelector.model_selector_name>
      </:trigger>
      <:title>Select a model</:title>
      <:description>Choose a model for this prompt.</:description>
      <Command.command id="variant-model-command">
        <Command.command_input
          controls="variant-model-list"
          aria-label="Search models"
          placeholder="Search models..."
        />
        <Command.command_list id="variant-model-list">
          <Command.command_empty>No models found.</Command.command_empty>
          <Command.command_group :for={chef <- ["OpenAI", "Anthropic", "Google"]} heading={chef}>
            <Command.command_item
              :for={model <- Enum.filter(@models, &(&1.chef == chef))}
              value={model.name}
              phx-click={
                JS.push("model", target: @target, value: %{id: model.id})
                |> LiveBase.Dialog.close("variant-model")
              }
            >
              <ModelSelector.model_selector_logo provider={model.provider} />
              <ModelSelector.model_selector_name>{model.name}</ModelSelector.model_selector_name>
              <ModelSelector.model_selector_logo_group>
                <ModelSelector.model_selector_logo
                  :for={provider <- model.providers}
                  provider={provider}
                />
              </ModelSelector.model_selector_logo_group>
              <LiveShadcn.Icon.icon :if={@model.id == model.id} name="check" />
            </Command.command_item>
          </Command.command_group>
        </Command.command_list>
      </Command.command>
    </Dialog.dialog>
    """
  end

  defp cursor_context(assigns) do
    ~H"""
    <HoverCard.hover_card
      id="cursor-files"
      trigger_variant="outline"
      trigger_size="icon-sm"
      class="w-[400px] p-0"
    >
      <:trigger><span aria-label="Add context">@</span></:trigger>
      <Command.command id="cursor-files-command">
        <Command.command_input
          controls="cursor-files-list"
          aria-label="Find context files"
          placeholder="Add files, folders, docs..."
        />
        <Command.command_list id="cursor-files-list">
          <Command.command_empty>No results found.</Command.command_empty>
          <Command.command_group heading="Added">
            <Command.command_item value="Active Tabs">Active Tabs ✓</Command.command_item>
          </Command.command_group>
          <Command.command_group heading="Other Files">
            <Command.command_item
              :for={source <- @sample_sources}
              :if={!Enum.any?(@refs, &(&1.id == source.id))}
              value={source.title <> " " <> source.filename}
              phx-click={JS.push("add-source", target: @target, value: %{id: source.id})}
            >
              <LiveShadcn.Icon.icon name="globe" /><span>{source.title}<small class="block">{source.filename}</small></span>
            </Command.command_item>
          </Command.command_group>
        </Command.command_list>
      </Command.command>
    </HoverCard.hover_card>
    <HoverCard.hover_card id="cursor-rules" trigger_variant="outline" trigger_size="sm">
      <:trigger><LiveShadcn.Icon.icon name="ruler" /> 1</:trigger>
      <p>Attached Project Rules</p><p>Always Apply:</p><p>ultracite.mdc</p><p>Click to manage</p>
    </HoverCard.hover_card>
    <HoverCard.hover_card
      id="cursor-tabs"
      trigger_variant="outline"
      trigger_size="sm"
      class="w-[300px]"
    >
      <:trigger><LiveShadcn.Icon.icon name="files" /> 1 Tab</:trigger>
      <PromptInput.prompt_input_tab>
        <PromptInput.prompt_input_tab_label>Active Tabs</PromptInput.prompt_input_tab_label>
        <PromptInput.prompt_input_tab_body>
          <PromptInput.prompt_input_tab_item>
            packages/elements/src/task-queue-panel.tsx
          </PromptInput.prompt_input_tab_item>
        </PromptInput.prompt_input_tab_body>
      </PromptInput.prompt_input_tab>
      <PromptInput.prompt_input_tab>
        <PromptInput.prompt_input_tab_label>Recents</PromptInput.prompt_input_tab_label>
        <PromptInput.prompt_input_tab_body>
          <PromptInput.prompt_input_tab_item :for={
            path <- [
              "apps/test/app/examples/task-queue-panel.tsx",
              "apps/test/app/page.tsx",
              "packages/elements/src/task.tsx",
              "apps/test/app/examples/prompt-input.tsx",
              "packages/elements/src/queue.tsx",
              "apps/test/app/examples/queue.tsx"
            ]
          }>
            {path}
          </PromptInput.prompt_input_tab_item>
        </PromptInput.prompt_input_tab_body>
      </PromptInput.prompt_input_tab>
      <p>Only file paths are included</p>
    </HoverCard.hover_card>
    """
  end

  defp shimmer_duration(assigns) do
    ~H"""
    <div class="flex flex-col gap-6 p-8">
      <div
        :for={
          {id, duration, label, text} <- [
            {"fast", 1, "Fast (1 second)", "Loading quickly..."},
            {"default", 2, "Default (2 seconds)", "Loading at normal speed..."},
            {"slow", 4, "Slow (4 seconds)", "Loading slowly..."},
            {"very-slow", 6, "Very Slow (6 seconds)", "Loading very slowly..."}
          ]
        }
        class="text-center"
      >
        <p class="mb-3 text-muted-foreground text-sm">{label}</p><Shimmer.shimmer
          id={"shimmer-" <> id}
          duration={duration}
        >
          {text}
        </Shimmer.shimmer>
      </div>
    </div>
    """
  end

  defp shimmer_elements(assigns) do
    ~H"""
    <div class="flex flex-col gap-6 p-8">
      <div class="text-center">
        <p>As paragraph (default)</p><Shimmer.shimmer id="shimmer-paragraph" as="p">
          This is rendered as a paragraph
        </Shimmer.shimmer>
      </div>
      <div class="text-center">
        <p>As heading</p><Shimmer.shimmer id="shimmer-heading" as="h2" class="font-bold text-2xl">
          Large Heading with Shimmer
        </Shimmer.shimmer>
      </div>
      <div class="text-center">
        <p>As span (inline)</p><div>
          Processing your request <Shimmer.shimmer id="shimmer-inline" as="span" class="inline">with AI magic</Shimmer.shimmer>...
        </div>
      </div>
      <div class="text-center">
        <p>As div with custom styling</p><Shimmer.shimmer
          id="shimmer-div"
          as="div"
          class="font-semibold text-lg"
        >
          Custom styled shimmer text
        </Shimmer.shimmer>
      </div>
    </div>
    """
  end

  defp custom_sources(assigns) do
    ~H"""
    <div style="height: 110px;">
      <Sources.sources id="custom-citations" title={custom_sources_title(assigns)} count={3}>
        <Sources.source
          :for={
            {href, title} <- [
              {"https://stripe.com/docs/api", "Stripe API Documentation"},
              {"https://docs.github.com/en/rest", "GitHub REST API"},
              {"https://docs.aws.amazon.com/sdk-for-javascript/", "AWS SDK for JavaScript"}
            ]
          }
          href={href}
          title={title}
        >
          {title}<LiveShadcn.Icon.icon name="external-link" class="size-4" />
        </Sources.source>
      </Sources.sources>
    </div>
    """
  end

  defp custom_sources_title(assigns) do
    ~H"""
    <p class="font-medium">Using 3 citations</p><LiveShadcn.Icon.icon
      name="chevron-down"
      class="size-4"
    />
    """
  end

  defp tool_example(assigns) do
    assigns = assign(assigns, tool: tool_data(assigns.state))

    ~H"""
    <div style="height: 500px;">
      <Tool.tool id={@id} title={@tool.name} state={@state} variant="secondary">
        <h3>Parameters</h3>
        <CodeBlock.code_block_content code={Jason.encode!(@tool.input, pretty: true)} language="json" />
        <h3 :if={@tool[:output]}>Result</h3>
        <CodeBlock.code_block_content
          :if={@tool[:output]}
          code={Jason.encode!(@tool.output)}
          language="json"
        />
        <div :if={@tool[:error]} class="rounded-md bg-destructive/10 p-3 text-foreground">
          <h3>Error</h3>{@tool.error}
        </div>
      </Tool.tool>
    </div>
    """
  end

  defp tool_data("input-available"),
    do: %{
      name: "image_generation",
      input: %{
        prompt: "A futuristic cityscape at sunset with flying cars",
        quality: "high",
        resolution: "1024x1024",
        style: "digital_art"
      }
    }

  defp tool_data("input-streaming"),
    do: %{
      name: "web_search",
      input: %{include_snippets: true, max_results: 10, query: "latest AI market trends 2024"}
    }

  defp tool_data("output-error"),
    do: %{
      name: "api_request",
      input: %{
        headers: %{
          "Authorization" => "Bearer <YOUR_TOKEN_HERE>",
          "Content-Type" => "application/json"
        },
        method: "GET",
        timeout: 5000,
        url: "https://api.example.com/data"
      },
      error:
        "Connection timeout: The request took longer than 5000ms to complete. Please check your network connection and try again."
    }

  defp tool_data("output-available") do
    output =
      for {id, name, email, date} <- [
            {1, "John Doe", "john@example.com", "2024-01-15"},
            {2, "Jane Smith", "jane@example.com", "2024-01-20"},
            {3, "Bob Wilson", "bob@example.com", "2024-02-01"},
            {4, "Alice Brown", "alice@example.com", "2024-02-10"},
            {5, "Charlie Davis", "charlie@example.com", "2024-02-15"}
          ],
          do: %{"User ID" => id, "Name" => name, "Email" => email, "Created At" => date}

    %{
      name: "database_query",
      input: %{
        database: "analytics",
        params: ["2024-01-01"],
        query: "SELECT COUNT(*) FROM users WHERE created_at >= ?"
      },
      output: output
    }
  end
end
