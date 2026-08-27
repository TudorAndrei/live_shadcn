defmodule LiveAiElements.Components.ModelSelector do
  @moduledoc """
  Model selector.

  Upstream exports 11 more parts, each a thin
  wrapper around a part of `<.dialog>`, `<.command>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/ModelSelectorLogo/class/0" => "size-3 dark:invert",
    "jsx/ModelSelectorLogoGroup/class/0" => "flex shrink-0 items-center -space-x-1 [&>img]:rounded-full [&>img]:bg-background [&>img]:p-px [&>img]:ring-1 dark:[&>img]:bg-foreground",
    "jsx/ModelSelectorName/class/0" => "flex-1 truncate text-left"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `model_selector_logo` part."
  attr(:provider, :any, default: nil)
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

  def model_selector_logo(assigns) do
    ~H"""
    <img
      alt={"#{@provider} logo"}
      height={12}
      src={"https://models.dev/logos/#{@provider}.svg"}
      width={12}
      class={[upstream_fact("jsx/ModelSelectorLogo/class/0"), (@class || "")]}
      {@rest}
    />
    """
  end

  @doc "The `model_selector_logo_group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def model_selector_logo_group(assigns) do
    ~H"""
    <div
      class={[
        upstream_fact("jsx/ModelSelectorLogoGroup/class/0"),
        (@class || "")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `model_selector_name` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def model_selector_name(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/ModelSelectorName/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
