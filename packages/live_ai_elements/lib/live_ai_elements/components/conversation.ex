defmodule LiveAiElements.Components.Conversation do
  @moduledoc """
  Conversation. Built on `shadcn/button`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Conversation/class/0" => "relative flex-1 overflow-y-hidden",
    "jsx/ConversationContent/class/0" => "flex flex-col gap-8 p-4"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Scroller

  @doc """
  Built on `shadcn/button`.

      <.conversation id="log" class="h-72">
        <p :for={line <- @lines}>{line}</p>
      </.conversation>

  The scrollbar is drawn rather than the platform's, so a style sheet can
  reach it. Everything that takes is a measurement — how much there is to
  scroll, how far down the reader is, how tall the thumb should be — and
  every one of them is made in the browser. The server is told none of it.
  """

  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")

  attr(:orientation, :string,
    default: "vertical",
    values: ["vertical", "horizontal"],
    doc: "Which way the scrollbar runs."
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global)
  slot(:inner_block, required: true, doc: "What scrolls.")

  def conversation(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook={Scroller.hook()}
      phx-mounted={Scroller.owned_attributes()}
      role="log"
      class={[upstream_fact("jsx/Conversation/class/0"), (@class || "")]}
      {@rest}
    >
      <div data-lb-scroller tabindex="0" style="overflow: auto" class={upstream_fact("jsx/ConversationContent/class/0")}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
