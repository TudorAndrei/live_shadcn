defmodule LiveShadcn.UI.Avatar do
  @moduledoc """
  Avatar. Displays a user's profile picture, initials, or fallback icon.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Avatar/class/0" => "cn-avatar group/avatar relative flex shrink-0 select-none after:absolute after:inset-0 after:border after:border-border after:mix-blend-darken dark:after:mix-blend-lighten",
    "jsx/AvatarFallback/class/0" => "cn-avatar-fallback flex size-full items-center justify-center text-sm group-data-[size=sm]/avatar:text-xs",
    "jsx/AvatarGroup/class/0" => "cn-avatar-group group/avatar-group flex -space-x-2 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background",
    "jsx/AvatarGroupCount/class/0" => "cn-avatar-group-count relative flex shrink-0 items-center justify-center ring-2 ring-background",
    "jsx/AvatarImage/class/0" => "cn-avatar-image aspect-square size-full object-cover",
    "port/class/0" => "cn-avatar-badge absolute right-0 bottom-0 z-10 inline-flex items-center justify-center rounded-full bg-blend-color ring-2 select-none group-data-[size=sm]/avatar:size-2 group-data-[size=sm]/avatar:[&>svg]:hidden group-data-[size=default]/avatar:size-2.5 group-data-[size=default]/avatar:[&>svg]:size-2 group-data-[size=lg]/avatar:size-3 group-data-[size=lg]/avatar:[&>svg]:size-2"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `avatar` part."
  attr(:size, :string, default: "default", values: ["default", "sm", "lg"])
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def avatar(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "avatar"}
      data-size={@size}
      class={[
        upstream_fact("jsx/Avatar/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The image to be displayed in the avatar."

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

  def avatar_image(assigns) do
    ~H"""
    <img
      data-slot={@rest[:"data-slot"] || "avatar-image"}
      class={[upstream_fact("jsx/AvatarImage/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    />
    """
  end

  @doc "Rendered when the image fails to load or when no image is provided."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def avatar_fallback(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "avatar-fallback"}
      class={[
        upstream_fact("jsx/AvatarFallback/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `avatar-group` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def avatar_group(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "avatar-group"}
      class={[
        upstream_fact("jsx/AvatarGroup/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `avatar-group-count` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def avatar_group_count(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "avatar-group-count"}
      class={[
        upstream_fact("jsx/AvatarGroupCount/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `avatar-badge` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def avatar_badge(assigns) do
    ~H"""
    <span
      data-slot={@rest[:"data-slot"] || "avatar-badge"}
      class={[
        upstream_fact("port/class/0"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end