defmodule LiveShadcn.UI.Progress do
  @moduledoc """
  Progress. Groups all parts of the progress bar and provides the task completion status to screen readers.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Progress/class/0" => "cn-progress-root flex flex-wrap gap-3",
    "jsx/ProgressIndicator/class/0" => "cn-progress-indicator h-full transition-all",
    "jsx/ProgressLabel/class/0" => "cn-progress-label",
    "jsx/ProgressTrack/class/0" =>
      "cn-progress-track relative flex w-full items-center overflow-x-hidden",
    "jsx/ProgressValue/class/0" => "cn-progress-value"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "Groups all parts of the progress bar and provides the task completion status to screen readers."
  attr(:value, :string, default: nil)
  attr(:label, :string, default: nil, doc: "The accessible name of the progress bar.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def progress(assigns) do
    assigns = assign(assigns, :state, progress_state(assigns.value))

    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "progress"}
      role="progressbar"
      aria-label={@label}
      aria-valuemin="0"
      aria-valuemax="100"
      aria-valuenow={@value}
      aria-valuetext={if(@value, do: "#{@value}%")}
      data-progressing={flag(@state == :progressing)}
      data-complete={flag(@state == :complete)}
      data-indeterminate={flag(@state == :indeterminate)}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/Progress/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
      <.progress_track state={@state}>
        <.progress_indicator value={@value} state={@state} />
      </.progress_track>
      <span role="presentation" style="clip-path: inset(50%); overflow: hidden; white-space: nowrap; border: 0px; padding: 0px; width: 1px; height: 1px; margin: -1px; position: fixed; top: 0px; left: 0px;">x</span>
    </div>
    """
  end

  @doc "Contains the progress bar indicator."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:state, :atom, default: :progressing, values: [:progressing, :complete, :indeterminate])
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def progress_track(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "progress-track"}
      data-progressing={flag(@state == :progressing)}
      data-complete={flag(@state == :complete)}
      data-indeterminate={flag(@state == :indeterminate)}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/ProgressTrack/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Visualizes the completion status of the task."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:value, :string, default: nil)
  attr(:state, :atom, default: :progressing, values: [:progressing, :complete, :indeterminate])
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def progress_indicator(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "progress-indicator"}
      data-progressing={flag(@state == :progressing)}
      data-complete={flag(@state == :complete)}
      data-indeterminate={flag(@state == :indeterminate)}
      style={if(@value, do: "inset-inline-start: 0px; height: inherit; width: #{@value}%")}
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/ProgressIndicator/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "An accessible label for the progress bar."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def progress_label(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "progress-label"}
      role="presentation"
      data-progressing
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/ProgressLabel/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "A text element displaying the current value."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def progress_value(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "progress-value"}
      aria-hidden="true"
      data-progressing
      class={LiveShadcn.Cn.merge([upstream_fact("jsx/ProgressValue/class/0"), @class])}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp progress_state(nil), do: :indeterminate

  defp progress_state(value) do
    case Float.parse(to_string(value)) do
      {number, _rest} when number >= 100 -> :complete
      {_number, _rest} -> :progressing
      :error -> :indeterminate
    end
  end

  defp flag(true), do: ""
  defp flag(_state), do: nil
end
