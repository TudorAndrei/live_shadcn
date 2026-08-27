defmodule LiveAiElements.Components.Image do
  @moduledoc """
  Image.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Image/class/0" => "h-auto max-w-full overflow-hidden rounded-md"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `image` part."
  attr(:alt, :string, default: nil)
  attr(:base64, :string, default: nil)
  attr(:media_type, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: [
      "data-slot",
      "src",
      "srcset",
      "sizes",
      "alt",
      "loading",
      "decoding",
      "width",
      "height"
    ]
  )

  def image(assigns) do
    ~H"""
    <img
      alt={@alt}
      src={"data:#{@media_type};base64,#{@base64}"}
      class={[upstream_fact("jsx/Image/class/0"), (@class || "")]}
      {@rest}
    />
    """
  end
end
