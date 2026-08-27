defmodule LiveAiElements.Components.Shimmer do
  @moduledoc """
  Shimmer.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "port/class/0" => "relative inline-block bg-[length:250%_100%,auto] bg-clip-text text-transparent [--bg:linear-gradient(90deg,#0000_calc(50%-var(--spread)),var(--color-background),#0000_calc(50%+var(--spread)))] [background-repeat:no-repeat,padding-box]"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `shimmer` part."
  attr(:as, :string, default: "p")
  attr(:duration, :any, default: 2)
  attr(:dynamic_spread, :string, default: nil)
  attr(:spread, :any, default: 2)
  attr(:id, :string, required: true, doc: "The hook needs one to be found by.")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def shimmer(assigns) do
    ~H"""
    <p
      id={@id}
      phx-hook={LiveBase.Shimmer.hook()}
      data-lb-shimmer="100% center,0% center"
      data-lb-duration={trunc(@duration * 1000)}
      style={"--spread: #{"#{@dynamic_spread}px"}; background-image: var(--bg), linear-gradient(var(--color-muted-foreground), var(--color-muted-foreground))"}
      class={[
        upstream_fact("port/class/0"),
        (@class || "")
      ]}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end
end
