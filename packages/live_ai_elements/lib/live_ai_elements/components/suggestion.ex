defmodule LiveAiElements.Components.Suggestion do
  @moduledoc """
  Suggestion. Built on `shadcn/scroll-area`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ScrollArea/class/1" =>
      "cn-scroll-area-viewport size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1",
    "jsx/ScrollBar/class/0" =>
      "cn-scroll-area-scrollbar flex touch-none p-px transition-colors select-none",
    "jsx/ScrollBar/class/1" => "cn-scroll-area-thumb relative flex-1 bg-border",
    "jsx/Suggestion/class/0" => "cursor-pointer rounded-full px-4",
    "jsx/Suggestions/class/1" => "flex w-max flex-nowrap items-center gap-2",
    "port/class/0" => "cn-scroll-area relative w-full overflow-x-auto whitespace-nowrap",
    "port/class/1" =>
      "cn-scroll-area-scrollbar flex touch-none p-px transition-colors select-none hidden"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `scroll-area` part."
  attr(:orientation, :string, default: "horizontal")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def suggestions(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "scroll-area"}
      class={upstream_fact("port/class/0")}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <div
        data-slot="scroll-area-viewport"
        class="focus-visible:ring-ring/50 size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:outline-1"
        style="overflow: scroll;"
      >
        <div
          style="min-width: 100%; display: table;"
        >
          <div class={[upstream_fact("jsx/Suggestions/class/1"), @class]}>
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc "The `suggestion` part."
  attr(:size, :string, default: "sm")
  attr(:suggestion, :string, default: nil)
  attr(:variant, :string, default: "outline")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def suggestion(assigns) do
    ~H"""
    <button
      data-slot={@rest[:"data-slot"] || "button"}
      type="button"
      class={[
        Shadcn.button_class(@size, @variant),
        upstream_fact("jsx/Suggestion/class/0"),
        "!gap-1.5 !rounded-full",
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <%= if @inner_block == [] do %>
        {@suggestion}
      <% end %>
      {render_slot(@inner_block)}
    </button>
    """
  end
end
