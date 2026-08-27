defmodule LiveAiElements.Components.Question do
  @moduledoc """
  Question. Built on `shadcn/textarea`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Question/class/0" => "space-y-4 rounded-lg border bg-background p-4",
    "jsx/QuestionActions/class/0" => "flex items-center justify-end gap-2",
    "jsx/QuestionDescription/class/0" => "text-muted-foreground text-sm",
    "jsx/QuestionOption/class/0" => "h-auto whitespace-normal",
    "jsx/QuestionOptions/class/0" => "flex flex-wrap gap-2",
    "jsx/QuestionPrompt/class/0" => "font-medium text-sm",
    "port/class/0" => "cn-textarea flex field-sizing-content min-h-16 w-full outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50 min-h-20"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `question` part."
  attr(:default_value, :string, default: "EMPTY_VALUE")
  attr(:disabled, :boolean, default: false)
  attr(:selection_mode, :string, default: "single")
  attr(:value, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: ["data-slot", "action", "method", "enctype", "novalidate", "target"]
  )

  slot(:inner_block)

  def question(assigns) do
    ~H"""
    <form class={[upstream_fact("jsx/Question/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </form>
    """
  end

  @doc "The `question_prompt` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def question_prompt(assigns) do
    ~H"""
    <p class={[upstream_fact("jsx/QuestionPrompt/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "The `question_description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def question_description(assigns) do
    ~H"""
    <p class={[upstream_fact("jsx/QuestionDescription/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "The `question_options` part."
  attr(:selection_mode, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def question_options(assigns) do
    ~H"""
    <div
      role={if(@selection_mode == "single", do: "radiogroup", else: "group")}
      class={[upstream_fact("jsx/QuestionOptions/class/0"), (@class || "")]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `question_option` part."
  attr(:disabled, :string, default: nil)
  attr(:is_selected, :string, default: nil)
  attr(:role, :string, default: nil)
  attr(:selected_values, :string, default: nil)
  attr(:selection_mode, :string, default: nil)
  attr(:size, :string, default: "default")
  attr(:value, :string, default: nil)
  attr(:variant, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def question_option(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      aria-checked={@is_selected}
      disabled={@disabled}
      role={@role}
      type="button"
      size={@size}
      variant={@variant || if(@is_selected, do: "default", else: "outline")}
      class={[upstream_fact("jsx/QuestionOption/class/0"), @class]}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {@value}
      <% end %>
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end

  @doc "The `textarea` part."
  attr(:disabled, :string, default: nil)
  attr(:text, :string, default: nil)
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

  def question_input(assigns) do
    ~H"""
    <textarea
      phx-no-format
      data-slot={@rest[:"data-slot"] || "textarea"}
      disabled={@disabled}
      class={[
        upstream_fact("port/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{@text}{render_slot(@inner_block)}</textarea>
    """
  end

  @doc "The `question_actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def question_actions(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/QuestionActions/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `question_submit` part."
  attr(:disabled, :string, default: nil)
  attr(:has_response, :string, default: nil)
  attr(:selected_values, :string, default: nil)
  attr(:size, :string, default: "default")
  attr(:text, :string, default: nil)
  attr(:variant, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def question_submit(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      disabled={@disabled || !@has_response}
      type="submit"
      size={@size}
      variant={@variant}
      {@rest}
    >
      {render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end
end
