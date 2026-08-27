defmodule LiveAiElements.Components.Transcription do
  @moduledoc """
  Transcription.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Transcription/class/0" => "flex flex-wrap gap-1 text-sm leading-relaxed",
    "jsx/TranscriptionSegment/class/0" => "inline text-left",
    "jsx/TranscriptionSegment/class/1" => "text-primary",
    "jsx/TranscriptionSegment/class/2" => "text-muted-foreground",
    "jsx/TranscriptionSegment/class/3" => "text-muted-foreground/60",
    "jsx/TranscriptionSegment/class/4" => "cursor-pointer hover:text-foreground",
    "jsx/TranscriptionSegment/class/5" => "cursor-default"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `transcription` part."
  attr(:current_time, :any, default: nil)
  attr(:segments, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:children)
  slot(:inner_block)

  def transcription(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "transcription"}
      class={[upstream_fact("jsx/Transcription/class/0"), @class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@children)}
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `transcription-segment` part."
  attr(:index, :any, default: nil)
  attr(:is_active, :string, default: nil)
  attr(:is_past, :string, default: nil)
  attr(:segment, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def transcription_segment(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "transcription-segment"}
      data-active={@is_active}
      data-index={@index}
      type="button"
      class={[
        upstream_fact("jsx/TranscriptionSegment/class/0"),
        if(@is_active, do: upstream_fact("jsx/TranscriptionSegment/class/1"), else: nil),
        if(@is_past, do: upstream_fact("jsx/TranscriptionSegment/class/2"), else: nil),
        if(!(@is_active || @is_past), do: upstream_fact("jsx/TranscriptionSegment/class/3"), else: nil),
        upstream_fact("jsx/TranscriptionSegment/class/4"),
        if(!true, do: upstream_fact("jsx/TranscriptionSegment/class/5"), else: nil),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {@segment.text}{render_slot(@inner_block)}
    </button>
    """
  end
end
