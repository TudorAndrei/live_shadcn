defmodule LiveAiElements.Components.Plan do
  @moduledoc """
  Plan. Built on `shadcn/button`, `shadcn/card`, `shadcn/collapsible`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.

  | Upstream | Digest |
  |---|---|
  | `ai_elements/plan.tsx` | `bfa20e90199f` |
  """

  use Phoenix.Component

  alias LiveAiElements.Shadcn

  # live-shadcn: upstream facts start
  @upstream_facts %{
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
    "jsx/CardContent/class/0" => "cn-card-content",
    "jsx/PlanTrigger/class/1" => "size-4",
    "jsx/PlanTrigger/class/2" => "sr-only",
    "port/class/0" =>
      "cn-button group/button inline-flex shrink-0 items-center justify-center whitespace-nowrap transition-all outline-none select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 size-8",
    "port/class/1" => "cn-card group/card flex flex-col shadow-none"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Disclosure

  @doc """
  Built on `shadcn/button`, `shadcn/card`, `shadcn/collapsible`.

      <.plan id="details" title="Show details">
        The panel body.
      </.plan>

  Opening and closing runs entirely on the client. The server is not told,
  and does not need to be: the state is whether a reader is looking at it.
  """
  attr(:id, :string, required: true, doc: "Every id inside the component derives from it.")
  attr(:title, :any, required: true, doc: "The trigger content.")

  attr(:open, :boolean,
    default: false,
    doc:
      "Whether the collapsible panel is initially open. To render a controlled collapsible, use the `open` prop instead."
  )

  attr(:disabled, :boolean,
    default: false,
    doc: "Whether the component should ignore user interaction."
  )

  attr(:orientation, :string, default: "vertical", doc: "")
  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:content_class, :any, default: nil, doc: "Appended to the content class string.")
  attr(:trigger_class, :any, default: nil, doc: "Appended to the trigger class string.")
  attr(:rest, :global)

  slot(:inner_block, required: true, doc: "The panel body.")
  attr(:size, :any, default: nil)
  attr(:variant, :any, default: nil)

  def plan(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "plan"}
      id={@id}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      data-size={@size}
      class={[Shadcn.card_class(:card), "!shadow-none", @class || ""]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <button
        data-slot="plan-trigger"
        id={Disclosure.trigger_id(@id)}
        type="button"
        aria-expanded={to_string(@open)}
        aria-controls={Disclosure.panel_id(@id)}
        phx-click={interactive(@disabled, Disclosure.toggle(item: @id, root: @id, multiple: true))}
        phx-mounted={Disclosure.owned_attributes(:trigger)}
        data-panel-open={flag(@open)}
        class={[
          Shadcn.button_class("icon", "ghost"),
          "!size-8",
          @trigger_class
        ]}
      >
        <LiveShadcn.Icon.icon name="chevrons-up-down" class={upstream_fact("jsx/PlanTrigger/class/1")} /><span class={upstream_fact("jsx/PlanTrigger/class/2")}>Toggle plan</span>{@title}
      </button>
      <div
        data-slot="plan-content"
        id={Disclosure.panel_id(@id)}
        role="region"
        aria-labelledby={Disclosure.trigger_id(@id)}
        hidden={not @open}
        phx-hook={Disclosure.hook()}
        phx-mounted={Disclosure.owned_attributes(:panel)}
        data-lb-height-var="--collapsible-panel-height"
        data-lb-width-var="--collapsible-panel-width"
        data-open={flag(@open)}
        data-closed={flag(not @open)}
        class={[Shadcn.card_class(:content), @content_class || ""]}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # A disabled disclosure ignores interaction. `aria-disabled` and
  # `pointer-events-none` say so to a reader and to a mouse, but a keypress
  # on a focused trigger reaches neither, so the command itself is withheld.
  defp interactive(false, command), do: command
  defp interactive(_disabled, _command), do: nil

  # An HTML attribute with no value, or no attribute at all. Base UI marks
  # state by presence, so `data-open=""` and a missing `data-open` are the
  # two states a shadcn class string distinguishes.
  defp flag(true), do: ""
  defp flag(_state), do: nil
end
