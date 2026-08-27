defmodule LiveAiElements.Components.AudioPlayer do
  @moduledoc """
  Audio player. Built on `shadcn/button`, `shadcn/button-group`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "cva/buttonGroupVariants/default/orientation" => "horizontal",
    "cva/buttonGroupVariants/variant/orientation/horizontal" => "cn-button-group-orientation-horizontal *:data-slot:rounded-r-none [&>[data-slot]~[data-slot]]:rounded-l-none [&>[data-slot]~[data-slot]]:border-l-0",
    "cva/buttonGroupVariants/variant/orientation/vertical" => "cn-button-group-orientation-vertical flex-col *:data-slot:rounded-b-none [&>[data-slot]~[data-slot]]:rounded-t-none [&>[data-slot]~[data-slot]]:border-t-0",
    "cva/buttonVariants/base" => "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    "cva/buttonVariants/variant/size/default" => "cn-button-size-default",
    "cva/buttonVariants/variant/size/icon" => "cn-button-size-icon",
    "cva/buttonVariants/variant/size/icon-lg" => "cn-button-size-icon-lg",
    "cva/buttonVariants/variant/size/icon-sm" => "cn-button-size-icon-sm",
    "cva/buttonVariants/variant/size/icon-xs" => "cn-button-size-icon-xs",
    "cva/buttonVariants/variant/size/lg" => "cn-button-size-lg",
    "cva/buttonVariants/variant/size/sm" => "cn-button-size-sm",
    "cva/buttonVariants/variant/size/xs" => "cn-button-size-xs",
    "cva/buttonVariants/variant/variant/default" => "cn-button-variant-default",
    "cva/buttonVariants/variant/variant/destructive" => "cn-button-variant-destructive",
    "cva/buttonVariants/variant/variant/ghost" => "cn-button-variant-ghost",
    "cva/buttonVariants/variant/variant/link" => "cn-button-variant-link",
    "cva/buttonVariants/variant/variant/outline" => "cn-button-variant-outline",
    "cva/buttonVariants/variant/variant/secondary" => "cn-button-variant-secondary",
    "port/class/0" => "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-transparent",
    "port/class/1" => "cn-button-group-text flex items-center [&_svg]:pointer-events-none bg-transparent",
    "port/class/2" => "cn-button-group-text flex items-center [&_svg]:pointer-events-none bg-transparent tabular-nums"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @variant_classes (for {"cva/" <> path, value} <- @upstream_facts,
                        [table, "variant", group, choice] <- [String.split(path, "/")],
                        reduce: %{} do
                      variants ->
                        put_in(
                          variants,
                          [
                            Access.key(table, %{}),
                            Access.key(group, %{}),
                            Access.key(choice, nil)
                          ],
                          value
                        )
                    end)

  @doc "The `audio-player` part."
  attr(:style, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player(assigns) do
    ~H"""
    <media-controller
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player"}
      audio
      style={"--media-background-color: transparent; --media-button-icon-height: 1rem; --media-button-icon-width: 1rem; --media-control-background: transparent; --media-control-hover-background: var(--color-accent); --media-control-padding: 0; --media-font: var(--font-sans); --media-font-size: 10px; --media-icon-color: currentColor; --media-preview-time-background: var(--color-background); --media-preview-time-border-radius: var(--radius-md); --media-preview-time-text-shadow: none; --media-primary-color: var(--color-primary); --media-range-bar-color: var(--color-primary); --media-range-track-background: var(--color-secondary); --media-secondary-color: var(--color-secondary); --media-text-color: var(--color-foreground); --media-tooltip-arrow-display: none; --media-tooltip-background: var(--color-background); --media-tooltip-border-radius: var(--radius-md); #{@style}"}
      {Map.drop(@rest, [:"data-slot"])}
    >{render_slot(@inner_block)}</media-controller>
    """
  end

  @doc "The `audio-player-element` part."
  attr(:data, :string, default: nil)
  attr(:src, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")

  attr(:rest, :global,
    include: ["data-slot", "src", "controls", "autoplay", "loop", "muted", "preload"]
  )

  slot(:inner_block)

  def audio_player_element(assigns) do
    ~H"""
    <audio
      data-slot={@rest[:"data-slot"] || "audio-player-element"}
      slot="media"
      src={if(@src, do: @src, else: "data:#{@data.media_type};base64,#{@data.base64}")}
      {Map.drop(@rest, [:"data-slot"])}
    >
      {render_slot(@inner_block)}
    </audio>
    """
  end

  @doc "The `audio-player-control-bar` part."
  attr(:orientation, :string,
    default: @upstream_facts["cva/buttonGroupVariants/default/orientation"]
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player_control_bar(assigns) do
    ~H"""
    <media-control-bar
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player-control-bar"}
      {Map.drop(@rest, [:"data-slot"])}
    ><LiveShadcn.UI.ButtonGroup.button_group orientation={@orientation}>
    {render_slot(@inner_block)}
    </LiveShadcn.UI.ButtonGroup.button_group></media-control-bar>
    """
  end

  @doc "The `audio-player-play-button` part."
  attr(:size, :string,
    default: "icon-sm",
    values: @variant_classes |> get_in(["buttonVariants", "size"]) |> Map.keys() |> Enum.sort()
  )

  attr(:variant, :string,
    default: "outline",
    values: @variant_classes |> get_in(["buttonVariants", "variant"]) |> Map.keys() |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player_play_button(assigns) do
    ~H"""
    <media-play-button
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player-play-button"}
      class={[
        variant_class("buttonVariants", "size", @size),
        variant_class("buttonVariants", "variant", @variant),
        upstream_fact("port/class/0"),
        @class
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{render_slot(@inner_block)}</media-play-button>
    """
  end

  @doc "The `audio-player-seek-backward-button` part."
  attr(:seek_offset, :string, default: "10")

  attr(:size, :string,
    default: "icon-sm",
    values: @variant_classes |> get_in(["buttonVariants", "size"]) |> Map.keys() |> Enum.sort()
  )

  attr(:variant, :string,
    default: "outline",
    values: @variant_classes |> get_in(["buttonVariants", "variant"]) |> Map.keys() |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player_seek_backward_button(assigns) do
    ~H"""
    <media-seek-backward-button
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player-seek-backward-button"}
      seekOffset={@seek_offset}
      class={[
        variant_class("buttonVariants", "size", @size),
        variant_class("buttonVariants", "variant", @variant),
        upstream_fact("cva/buttonVariants/base")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{render_slot(@inner_block)}</media-seek-backward-button>
    """
  end

  @doc "The `audio-player-seek-forward-button` part."
  attr(:seek_offset, :string, default: "10")

  attr(:size, :string,
    default: "icon-sm",
    values: @variant_classes |> get_in(["buttonVariants", "size"]) |> Map.keys() |> Enum.sort()
  )

  attr(:variant, :string,
    default: "outline",
    values: @variant_classes |> get_in(["buttonVariants", "variant"]) |> Map.keys() |> Enum.sort()
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player_seek_forward_button(assigns) do
    ~H"""
    <media-seek-forward-button
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player-seek-forward-button"}
      seekOffset={@seek_offset}
      class={[
        variant_class("buttonVariants", "size", @size),
        variant_class("buttonVariants", "variant", @variant),
        upstream_fact("cva/buttonVariants/base")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{render_slot(@inner_block)}</media-seek-forward-button>
    """
  end

  @doc "The `audio-player-time-display` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player_time_display(assigns) do
    ~H"""
    <media-time-display
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player-time-display"}
      class={[
        upstream_fact("port/class/2"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{render_slot(@inner_block)}</media-time-display>
    """
  end

  @doc "The `audio-player-time-range` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player_time_range(assigns) do
    ~H"""
    <media-time-range
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player-time-range"}
      class={[
        upstream_fact("port/class/1"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{render_slot(@inner_block)}</media-time-range>
    """
  end

  @doc "The `audio-player-duration-display` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player_duration_display(assigns) do
    ~H"""
    <media-duration-display
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player-duration-display"}
      class={[
        upstream_fact("port/class/2"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{render_slot(@inner_block)}</media-duration-display>
    """
  end

  @doc "The `audio-player-mute-button` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player_mute_button(assigns) do
    ~H"""
    <media-mute-button
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player-mute-button"}
      class={[
        upstream_fact("port/class/1"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{render_slot(@inner_block)}</media-mute-button>
    """
  end

  @doc "The `audio-player-volume-range` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def audio_player_volume_range(assigns) do
    ~H"""
    <media-volume-range
      phx-no-format
      data-slot={@rest[:"data-slot"] || "audio-player-volume-range"}
      class={[
        upstream_fact("port/class/1"),
        (@class || "")
      ]}
      {Map.drop(@rest, [:"data-slot"])}
    >{render_slot(@inner_block)}</media-volume-range>
    """
  end

  defp variant_class(table, group, value),
    do: get_in(@variant_classes, [table, group, value])
end
