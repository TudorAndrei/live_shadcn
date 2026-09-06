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
    "jsx/QuestionnaireChoice/class/7" =>
      "cn-questionnaire-choice-shortcut cn-questionnaire-shortcut pointer-events-none ms-auto hidden shrink-0 group-data-[shortcut]/questionnaire-choice:inline-flex",
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

  defp initial_item(default_item, nil), do: default_item

  defp initial_item(default_item, items) do
    enabled_items =
      Enum.reject(items, fn item ->
        Map.get(item, :disabled, Map.get(item, "disabled", false))
      end)

    names = Enum.map(enabled_items, &(Map.get(&1, :name) || Map.get(&1, "name")))

    if default_item in names do
      default_item
    else
      List.first(names)
    end
  end

  defp items_json(nil), do: nil
  defp items_json(items), do: Jason.encode!(items)

  defp merged_class(parts), do: LiveShadcn.Cn.merge(parts)

  defp action_class(fact, variant, size, class) do
    merged_class([
      LiveShadcn.UI.Button.button_class(variant: variant, size: size),
      upstream_fact(fact),
      class
    ])
  end

  @doc "The `questionnaire` part."

  attr(:id, :string, required: true, doc: "The stable DOM id required by the LiveView hook.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:default_item, :string, default: nil)
  attr(:item, :string, default: nil)
  attr(:items, :list, default: nil, doc: "The declared item names and their choice definitions.")
  attr(:shortcuts, :string, default: nil)
  attr(:on_item_change, :string, default: nil, doc: "A LiveView event emitted when the active item changes.")
  attr(:on_submit, :string, default: nil, doc: "A LiveView submit event.")
  attr(:on_reset, :string, default: nil, doc: "A LiveView reset event.")

  attr(:rest, :global,
    include: [
      "data-slot",
      "action",
      "method",
      "enctype",
      "novalidate",
      "target",
      "data-lb-close-dialog-on-submit",
      "data-lb-reset-on-dialog-close"
    ]
  )

  slot(:inner_block)

  def questionnaire(assigns) do
    ~H"""
    <form
      id={@id}
      data-slot={@rest[:"data-slot"] || "questionnaire"}
      data-lb-questionnaire
      data-default-item={initial_item(@default_item, @items)}
      data-item={@item}
      data-lb-items={items_json(@items)}
      data-controlled={if(is_nil(@item), do: nil, else: "")}
      data-shortcuts={@shortcuts}
      data-lb-item-change-event={@on_item_change}
      phx-hook={LiveBase.Questionnaire.hook()}
      phx-submit={@on_submit}
      phx-reset={@on_reset}
      class={merged_class([upstream_fact("jsx/Questionnaire/class/0"), @class])}
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
      class={merged_class([upstream_fact("jsx/QuestionnaireActions/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `questionnaire-choice` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:value, :string, required: true)
  attr(:checked, :boolean, default: nil)
  attr(:default_checked, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "radio")
  attr(:on_change, :string, default: nil, doc: "A LiveView change event for this choice.")
  attr(:rest, :global, include: ["data-slot", "for", "name", "required", "aria-describedby"])
  slot(:inner_block)

  def questionnaire_choice(assigns) do
    ~H"""
    <label
      data-slot={@rest[:"data-slot"] || "questionnaire-choice"}
      data-type={@type}
      data-disabled={if(@disabled, do: "")}
      class={merged_class([upstream_fact("port/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <input
        data-slot="questionnaire-choice-input"
        type={@type}
        value={@value}
        name={@rest[:name]}
        required={@rest[:required]}
        checked={if(is_nil(@checked), do: @default_checked, else: @checked)}
        disabled={@disabled}
        phx-change={@on_change}
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
      <span
        data-slot="questionnaire-choice-shortcut"
        aria-hidden="true"
        hidden
        class={upstream_fact("jsx/QuestionnaireChoice/class/7")}
      />
    </label>
    """
  end

  @doc "The `questionnaire-choice-description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "id"])
  slot(:inner_block)

  def questionnaire_choice_description(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "questionnaire-choice-description"}
      class={merged_class([upstream_fact("jsx/QuestionnaireChoiceDescription/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot", :name, :required])}
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
      class={merged_class([upstream_fact("jsx/QuestionnaireChoices/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot", :type])}
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
      class={merged_class([upstream_fact("jsx/QuestionnaireDescription/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot", :type])}
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
      hidden
      class={merged_class([upstream_fact("jsx/QuestionnaireError/class/0"), @class])}
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
        class={merged_class([upstream_fact("port/class/1"), @class])}
        {Map.drop(@rest, [:"data-slot"])}
      />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `questionnaire-item` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:name, :string, required: true)
  attr(:multiple, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:invalid, :boolean, default: false)
  attr(:on_status_change, :string, default: nil, doc: "A LiveView event emitted when this item status changes.")
  attr(:rest, :global, include: ["data-slot", "aria-describedby", "aria-keyshortcuts", "aria-labelledby"])
  slot(:inner_block)

  def questionnaire_item(assigns) do
    ~H"""
    <fieldset
      data-slot={@rest[:"data-slot"] || "questionnaire-item"}
      data-questionnaire-name={@name}
      data-required={if(@required, do: "")}
      data-multiple={if(@multiple, do: "")}
      data-disabled={if(@disabled, do: "")}
      data-invalid={if(@invalid, do: "")}
      data-lb-status-change-event={@on_status_change}
      aria-invalid={if(@invalid, do: "true")}
      disabled={@disabled}
      class={merged_class([upstream_fact("jsx/QuestionnaireItem/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot", :type])}
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
      data-questionnaire-action="next"
      type={@rest[:type] || "button"}
      data-size={@size}
      data-variant={@variant}
      class={action_class("jsx/QuestionnaireNext/class/0", @variant, @size, @class)}
      {Map.drop(@rest, [:"data-slot", :type])}
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
      data-questionnaire-action="previous"
      type={@rest[:type] || "button"}
      data-size={@size}
      data-variant={@variant}
      class={action_class("jsx/QuestionnairePrevious/class/0", @variant, @size, @class)}
      {Map.drop(@rest, [:"data-slot", :type])}
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
  attr(:format, :string, default: "question", values: ["question", "fraction", "checkpoint"])
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
      aria-valuemin="1"
      aria-valuemax={@total}
      aria-valuenow={@current}
      aria-valuetext={if(@current && @total, do: "Question #{@current} of #{@total}")}
      data-lb-progress-format={if(@format == "question", do: nil, else: @format)}
      class={merged_class([upstream_fact("jsx/QuestionnaireProgress/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= case @format do %>
        <% "fraction" -> %>
          {@current || 1} / {@total || 1}
        <% "checkpoint" -> %>
          <div class="mb-2 flex gap-1.5" aria-hidden="true">
            <span
              :for={index <- 1..(@total || 1)}
              data-lb-progress-segment
              class={if(index <= (@current || 1), do: "h-1.5 flex-1 rounded-full bg-primary", else: "h-1.5 flex-1 rounded-full bg-muted")}
            />
          </div>
          <span data-lb-progress-label>Checkpoint {@current || 1} of {@total || 1}</span>
        <% "question" -> %>
          {render_slot(@inner_block)}
      <% end %>
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
      data-questionnaire-action="skip"
      type={@rest[:type] || "button"}
      data-size={@size}
      data-variant={@variant}
      class={action_class("jsx/QuestionnaireSkip/class/0", @variant, @size, @class)}
      {Map.drop(@rest, [:"data-slot", :type])}
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
      data-questionnaire-action="submit"
      type={@rest[:type] || "submit"}
      data-size={@size}
      data-variant={@variant}
      class={action_class("jsx/QuestionnaireSubmit/class/0", @variant, @size, @class)}
      {Map.drop(@rest, [:"data-slot", :type])}
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
      class={merged_class([upstream_fact("jsx/QuestionnaireTitle/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </legend>
    """
  end
end
