defmodule LiveAiElements.Components.Question do
  @moduledoc """
  Question. Built on `shadcn/textarea`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn
  alias LiveShadcn.Cn

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Question/class/0" => "space-y-4 rounded-lg border bg-background p-4",
    "jsx/QuestionActions/class/0" => "flex items-center justify-end gap-2",
    "jsx/QuestionDescription/class/0" => "text-muted-foreground text-sm",
    "jsx/QuestionOption/class/0" => "h-auto whitespace-normal",
    "jsx/QuestionOptions/class/0" => "flex flex-wrap gap-2",
    "jsx/QuestionPrompt/class/0" => "font-medium text-sm",
    "port/class/0" =>
      "cn-textarea flex field-sizing-content min-h-16 w-full outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50 min-h-20"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)
  defp merged_class(classes), do: Cn.merge(classes)

  @doc "The `question` part."
  attr(:id, :string, required: true)
  attr(:default_value, :string, default: "EMPTY_VALUE")
  attr(:disabled, :boolean, default: false)
  attr(:on_submit, :string, default: nil, doc: "The LiveView event sent after a valid response.")
  attr(:selection_mode, :string, default: "single")
  attr(:value, :string, default: nil)
  attr(:selected_name, :string, default: "selected_values[]")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: ["data-slot", "action", "method", "enctype", "novalidate", "target"]
  )

  slot(:inner_block)

  def question(assigns) do
    ~H"""
    <form
      id={@id}
      data-selection-mode={@selection_mode}
      data-selected-name={@selected_name}
      data-question-submit-event={@on_submit}
      phx-hook={hook()}
      class={merged_class([upstream_fact("jsx/Question/class/0"), @class])}
      {@rest}
    >
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
    <p class={merged_class([upstream_fact("jsx/QuestionPrompt/class/0"), @class])} {@rest}>
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
    <p class={merged_class([upstream_fact("jsx/QuestionDescription/class/0"), @class])} {@rest}>
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
      class={merged_class([upstream_fact("jsx/QuestionOptions/class/0"), @class])}
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
  attr(:variant, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def question_option(assigns) do
    assigns = assign(assigns, :selected?, assigns.is_selected in [true, "true"])

    ~H"""
    <button
      aria-checked={to_string(@selected?)}
      data-slot={@rest[:"data-slot"] || "button"}
      data-question-option
      data-question-value={@value}
      disabled={@disabled}
      role={@role}
      type="button"
      class={merged_class([
        Shadcn.button_class(@size, @variant || if(@selected?, do: "default", else: "outline")),
        upstream_fact("jsx/QuestionOption/class/0"),
        "transition-[box-shadow]",
        @class
      ])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        {@value}
      <% end %>
      {render_slot(@inner_block)}
    </button>
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
      data-question-input
      phx-no-format
      data-slot={@rest[:"data-slot"] || "textarea"}
      disabled={@disabled}
      class={merged_class([
        Shadcn.textarea_class(),
        "min-h-20",
        @class
      ])}
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
    <div class={merged_class([upstream_fact("jsx/QuestionActions/class/0"), @class])} {@rest}>
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
    <button
      data-slot={@rest[:"data-slot"] || "button"}
      data-question-submit
      disabled={@disabled || !@has_response}
      type="submit"
      class={merged_class([Shadcn.button_class(@size, @variant), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "The client hook name the question root declares in `phx-hook`."
  def hook, do: "LiveAiElements.Components.Question.Question"

  @doc false
  def hook_script(assigns) do
    ~H"""
    <%!-- colocated-hook question.js#Question --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Question">
      const OPTION = "[data-question-option]";
      const DEFAULT_VARIANT = "bg-primary text-primary-foreground hover:bg-primary/90";
      const OUTLINE_VARIANT = "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50";
      const Question = {
        mounted() {
          this.onClick = (event) => {
            const option = event.target.closest(OPTION);
            if (!option || option.disabled) return;
            const selected = this.selected();
            const value = option.dataset.questionValue;
            if (this.el.dataset.selectionMode === "multiple") selected.has(value) ? selected.delete(value) : selected.add(value);
            else if (selected.has(value)) selected.delete(value);
            else {
              selected.clear();
              selected.add(value);
            }
            this.draw(selected);
          };
          this.onInput = () => this.updateSubmit(this.selected());
          this.onSubmit = (event) => this.submit(event);
          this.el.addEventListener("click", this.onClick);
          this.el.addEventListener("input", this.onInput);
          this.el.addEventListener("submit", this.onSubmit);
          this.draw(this.selected());
        },
        destroyed() {
          this.el.removeEventListener("click", this.onClick);
          this.el.removeEventListener("input", this.onInput);
          this.el.removeEventListener("submit", this.onSubmit);
        },
        selected() {
          return new Set([...this.el.querySelectorAll(OPTION)].filter((option) => option.getAttribute("aria-checked") === "true").map((option) => option.dataset.questionValue));
        },
        draw(selected) {
          for (const option of this.el.querySelectorAll(OPTION)) {
            const active = selected.has(option.dataset.questionValue);
            option.setAttribute("aria-checked", String(active));
            this.replaceVariant(option, active);
          }
          this.updateSubmit(selected);
        },
        replaceVariant(option, selected) {
          const from = selected ? OUTLINE_VARIANT : DEFAULT_VARIANT;
          const to = selected ? DEFAULT_VARIANT : OUTLINE_VARIANT;
          if (option.className.includes(from)) option.className = option.className.replace(from, to);
        },
        submit(event) {
          event.preventDefault();
          const selected = this.selected();
          const text = this.el.querySelector("[data-question-input]")?.value.trim() || "";
          if (selected.size === 0 && text.length === 0) return;
          const serverEvent = this.el.dataset.questionSubmitEvent;
          if (serverEvent && this.pushEvent) this.pushEvent(serverEvent, {
            selected_values: [...selected],
            text
          });
        },
        updateSubmit(selected) {
          const text = this.el.querySelector("[data-question-input]")?.value.trim() || "";
          const submit = this.el.querySelector("[data-question-submit]");
          if (submit) submit.disabled = selected.size === 0 && text.length === 0;
        }
      };
      export default Question;
    </script>
    <%!-- /colocated-hook --%>
    """
  end
end
