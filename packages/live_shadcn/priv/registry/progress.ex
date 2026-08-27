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
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def progress(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "progress"}
      style={"--progress-value: #{@value}"}
      class={[upstream_fact("jsx/Progress/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
      <.progress_track>
        <.progress_indicator />
      </.progress_track>
    </div>
    """
  end

  @doc "Contains the progress bar indicator."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def progress_track(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "progress-track"}
      class={[upstream_fact("jsx/ProgressTrack/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Visualizes the completion status of the task."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def progress_indicator(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "progress-indicator"}
      style="width: calc(var(--progress-value) * 1%)"
      class={[upstream_fact("jsx/ProgressIndicator/class/0"), (@class || "")]}
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
      class={[upstream_fact("jsx/ProgressLabel/class/0"), (@class || "")]}
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
      class={[upstream_fact("jsx/ProgressValue/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end