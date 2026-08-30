defmodule LiveShadcn.UI.Questionnaire do
  @moduledoc """
  Questionnaire.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Questionnaire/class/0" => "cn-questionnaire flex w-full min-w-0 flex-col",
    "jsx/QuestionnaireActions/class/0" =>
      "cn-questionnaire-actions grid min-h-11 w-full grid-cols-[minmax(0,1fr)_auto_auto] items-center",
    "jsx/QuestionnaireChoice/class/2" =>
      "cn-questionnaire-choice-input absolute inset-0 z-10 size-full cursor-pointer opacity-0",
    "jsx/QuestionnaireChoice/class/3" =>
      "cn-questionnaire-choice-indicator pointer-events-none relative flex shrink-0 items-center justify-center border group-data-[type=radio]/questionnaire-choice:rounded-full",
    "jsx/QuestionnaireChoice/class/4" =>
      "cn-questionnaire-choice-indicator-dot hidden rounded-full group-data-[type=checkbox]/questionnaire-choice:hidden group-data-checked/questionnaire-choice:block",
    "jsx/QuestionnaireChoice/class/5" =>
      "cn-questionnaire-choice-indicator-check hidden group-data-[type=radio]/questionnaire-choice:hidden group-data-checked/questionnaire-choice:block",
    "jsx/QuestionnaireChoice/class/6" =>
      "cn-questionnaire-choice-label cn-questionnaire-choice-content flex min-w-0 flex-1 flex-col leading-snug",
    "jsx/QuestionnaireChoiceDescription/class/0" => "cn-questionnaire-choice-description",
    "jsx/QuestionnaireChoices/class/0" =>
      "cn-questionnaire-choices group/questionnaire-choices grid min-w-0",
    "jsx/QuestionnaireDescription/class/0" =>
      "cn-questionnaire-description text-pretty text-muted-foreground",
    "jsx/QuestionnaireError/class/0" => "cn-questionnaire-error text-destructive",
    "jsx/QuestionnaireInput/class/0" =>
      "cn-questionnaire-input-wrapper group/questionnaire-input relative min-w-0",
    "jsx/QuestionnaireItem/class/0" => "cn-questionnaire-item min-w-0 border-0 p-0 outline-none",
    "jsx/QuestionnaireNext/class/0" =>
      "cn-questionnaire-next col-start-3 row-start-1 min-h-11 justify-self-end sm:min-h-0",
    "jsx/QuestionnairePrevious/class/0" =>
      "cn-questionnaire-previous col-start-1 row-start-1 min-h-11 justify-self-start sm:min-h-0",
    "jsx/QuestionnaireProgress/class/0" =>
      "cn-questionnaire-progress min-h-[1lh] w-fit min-w-[14ch] font-medium text-muted-foreground tabular-nums",
    "jsx/QuestionnaireSkip/class/0" =>
      "cn-questionnaire-skip col-start-2 row-start-1 min-h-11 justify-self-end sm:min-h-0",
    "jsx/QuestionnaireSubmit/class/0" =>
      "cn-questionnaire-submit col-start-3 row-start-1 min-h-11 justify-self-end sm:min-h-0",
    "jsx/QuestionnaireTitle/class/0" => "cn-questionnaire-title cn-font-heading text-pretty",
    "port/class/0" =>
      "cn-questionnaire-choice group/questionnaire-choice relative flex min-h-11 cursor-pointer items-start text-start transition-colors outline-none select-none data-disabled:pointer-events-none data-disabled:cursor-not-allowed data-disabled:opacity-50",
    "port/class/1" =>
      "cn-questionnaire-input min-h-11 w-full min-w-0 transition-[color,box-shadow,background-color] outline-none disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 sm:min-h-0 selection:bg-primary selection:text-primary-foreground placeholder:text-muted-foreground"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `questionnaire` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: ["data-slot", "action", "method", "enctype", "novalidate", "target"]
  )

  slot(:inner_block)

  def questionnaire(assigns) do
    ~H"""
    <form
      data-slot={@rest[:"data-slot"] || "questionnaire"}
      class={[upstream_fact("jsx/Questionnaire/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </form>
    """
  end

  @doc "The `questionnaire-actions` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def questionnaire_actions(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "questionnaire-actions"}
      class={[
        upstream_fact("jsx/QuestionnaireActions/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `questionnaire-choice` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "for"])
  slot(:inner_block)

  def questionnaire_choice(assigns) do
    ~H"""
    <label
      data-slot={@rest[:"data-slot"] || "questionnaire-choice"}
      class={[
        upstream_fact("port/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <input
        data-slot="questionnaire-choice-input"
        type="radio"
        class={upstream_fact("jsx/QuestionnaireChoice/class/2")}
      />
      <span
        data-slot="questionnaire-choice-indicator"
        aria-hidden="true"
        class={upstream_fact("jsx/QuestionnaireChoice/class/3")}
      >
        <span
          data-slot="questionnaire-choice-indicator-dot"
          class={upstream_fact("jsx/QuestionnaireChoice/class/4")}
        /><LiveShadcn.Icon.icon
          name="check"
          data-slot="questionnaire-choice-indicator-check"
          class={upstream_fact("jsx/QuestionnaireChoice/class/5")}
        />
      </span>
      <span
        data-slot="questionnaire-choice-label"
        class={upstream_fact("jsx/QuestionnaireChoice/class/6")}
      >
        {render_slot(@inner_block)}
      </span>
    </label>
    """
  end

  @doc "The `questionnaire-choice-description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def questionnaire_choice_description(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "questionnaire-choice-description"}
      class={[upstream_fact("jsx/QuestionnaireChoiceDescription/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `questionnaire-choices` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def questionnaire_choices(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "questionnaire-choices"}
      class={[upstream_fact("jsx/QuestionnaireChoices/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `questionnaire-description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def questionnaire_description(assigns) do
    ~H"""
    <p
      data-slot={@rest[:"data-slot"] || "questionnaire-description"}
      class={[upstream_fact("jsx/QuestionnaireDescription/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "The `questionnaire-error` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def questionnaire_error(assigns) do
    ~H"""
    <p
      data-slot={@rest[:"data-slot"] || "questionnaire-error"}
      class={[upstream_fact("jsx/QuestionnaireError/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "The `questionnaire-input-wrapper` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: [
      "data-slot",
      "type",
      "name",
      "value",
      "placeholder",
      "checked",
      "min",
      "max",
      "step",
      "minlength",
      "maxlength",
      "pattern",
      "readonly",
      "multiple",
      "autocomplete",
      "disabled",
      "required"
    ]
  )

  slot(:inner_block)

  def questionnaire_input(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-input-wrapper"
      class={upstream_fact("jsx/QuestionnaireInput/class/0")}
    >
      <input
        data-slot={@rest[:"data-slot"] || "questionnaire-input"}
        class={[
          upstream_fact("port/class/1"),
          (@class || "")
        ]}
        {Map.drop(@rest, [:"data-slot"])}
      />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `questionnaire-item` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def questionnaire_item(assigns) do
    ~H"""
    <fieldset
      data-slot={@rest[:"data-slot"] || "questionnaire-item"}
      class={[upstream_fact("jsx/QuestionnaireItem/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </fieldset>
    """
  end

  @doc "The `questionnaire-next` part."
  attr(:size, :string, default: "default")
  attr(:variant, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def questionnaire_next(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "questionnaire-next"}
      data-size={@size}
      data-variant={@variant}
      class={[
        upstream_fact("jsx/QuestionnaireNext/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        Next
      <% end %>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `questionnaire-previous` part."
  attr(:size, :string, default: "default")
  attr(:variant, :string, default: "outline")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def questionnaire_previous(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "questionnaire-previous"}
      data-size={@size}
      data-variant={@variant}
      class={[
        upstream_fact("jsx/QuestionnairePrevious/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        Previous
      <% end %>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `questionnaire-progress` part."

  attr(:current, :integer, default: nil, doc: "The current question number.")
  attr(:total, :integer, default: nil, doc: "The total question count.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def questionnaire_progress(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "questionnaire-progress"}
      role="progressbar"
      aria-label="Questionnaire progress"
      aria-live="polite"
      aria-valuemin={if(@total, do: "1")}
      aria-valuemax={@total}
      aria-valuenow={@current}
      aria-valuetext={if(@current && @total, do: "Question #{@current} of #{@total}")}
      class={[
        upstream_fact("jsx/QuestionnaireProgress/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `questionnaire-skip` part."
  attr(:size, :string, default: "default")
  attr(:variant, :string, default: "outline")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def questionnaire_skip(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "questionnaire-skip"}
      data-size={@size}
      data-variant={@variant}
      class={[
        upstream_fact("jsx/QuestionnaireSkip/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        Skip
      <% end %>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `questionnaire-submit` part."
  attr(:size, :string, default: "default")
  attr(:variant, :string, default: "default")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def questionnaire_submit(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "questionnaire-submit"}
      data-size={@size}
      data-variant={@variant}
      class={[
        upstream_fact("jsx/QuestionnaireSubmit/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        Submit
      <% end %>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The `questionnaire-title` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def questionnaire_title(assigns) do
    ~H"""
    <legend
      data-slot={@rest[:"data-slot"] || "questionnaire-title"}
      class={[upstream_fact("jsx/QuestionnaireTitle/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </legend>
    """
  end
end
