defmodule LiveAiElements.Components.VoiceSelector do
  @moduledoc """
  Voice selector. Built on `shadcn/dialog`.

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
    "jsx/VoiceSelectorAccent/class/0" => "text-muted-foreground text-xs",
    "jsx/VoiceSelectorAge/class/0" => "text-muted-foreground text-xs tabular-nums",
    "jsx/VoiceSelectorAttributes/class/0" => "flex items-center text-xs",
    "jsx/VoiceSelectorBullet/class/0" => "select-none text-border",
    "jsx/VoiceSelectorName/class/0" => "flex-1 truncate text-left font-medium",
    "jsx/VoiceSelectorPreview/class/0" => "size-3",
    "jsx/VoiceSelectorPreview/class/3" => "size-6"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `voice_selector_gender` part."
  attr(:icon, :string, default: nil)

  attr(:value, :string,
    default: nil,
    values: [nil, "male", "female", "transgender", "androgyne", "non-binary", "intersex"]
  )

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def voice_selector_gender(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/VoiceSelectorAccent/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {@icon}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `voice_selector_accent` part."
  attr(:emoji, :string, default: nil)
  attr(:value, :string, default: nil)
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def voice_selector_accent(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/VoiceSelectorAccent/class/0"), (@class || "")]} {@rest}>
      <%= if @inner_block == [] do %>
        {@emoji}
      <% end %>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `voice_selector_age` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def voice_selector_age(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/VoiceSelectorAge/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `voice_selector_name` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def voice_selector_name(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/VoiceSelectorName/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `voice_selector_description` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def voice_selector_description(assigns) do
    ~H"""
    <span class={[upstream_fact("jsx/VoiceSelectorAccent/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `voice_selector_attributes` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def voice_selector_attributes(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/VoiceSelectorAttributes/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The `voice_selector_bullet` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def voice_selector_bullet(assigns) do
    ~H"""
    <span aria-hidden="true" class={[upstream_fact("jsx/VoiceSelectorBullet/class/0"), (@class || "")]} {@rest}>
      &bull;{render_slot(@inner_block)}
    </span>
    """
  end

  @doc "The `voice_selector_preview` part."
  attr(:icon, :string, default: nil)
  attr(:loading, :boolean, default: nil)
  attr(:playing, :boolean, default: nil)
  attr(:size, :string, default: "icon-sm")
  attr(:variant, :string, default: "outline")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot", "type", "value", "name", "formaction", "disabled"])
  slot(:inner_block)

  def voice_selector_preview(assigns) do
    ~H"""
    <LiveShadcn.UI.Button.button
      aria-label={if(@playing, do: "Pause preview", else: "Play preview")}
      disabled={@loading}
      type="button"
      size={@size}
      variant={@variant}
      class={[upstream_fact("jsx/VoiceSelectorPreview/class/3"), (@class || "")]}
      {@rest}
    >
      <LiveShadcn.Icon.icon name="play" class={upstream_fact("jsx/VoiceSelectorPreview/class/0")} />{render_slot(@inner_block)}
    </LiveShadcn.UI.Button.button>
    """
  end
end
