defmodule LiveShadcn.UI.Collapsible do
  @moduledoc """
  Collapsible. Groups all parts of the collapsible.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.

  | Upstream | Digest |
  |---|---|
  | `shadcn/ui/collapsible.tsx` | `ead4349ff7b0` |
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{}
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  alias LiveBase.Disclosure

  @doc """
  Groups all parts of the collapsible.

      <.collapsible id="details" title="Show details">
        The panel body.
      </.collapsible>

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

  def collapsible(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "collapsible"}
      id={@id}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      class={[@class]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <button
        data-slot="collapsible-trigger"
        id={Disclosure.trigger_id(@id)}
        type="button"
        aria-expanded={to_string(@open)}
        aria-disabled={to_string(@disabled)}
        aria-controls={Disclosure.panel_id(@id)}
        phx-click={interactive(@disabled, Disclosure.toggle(item: @id, root: @id, multiple: true))}
        phx-mounted={Disclosure.owned_attributes(:trigger)}
        data-panel-open={flag(@open)}
      >
        {@title}
      </button>
      <div
        data-slot="collapsible-content"
        id={Disclosure.panel_id(@id)}
        aria-labelledby={Disclosure.trigger_id(@id)}
        hidden={not @open}
        phx-hook={Disclosure.hook()}
        phx-mounted={Disclosure.owned_attributes(:panel)}
        data-lb-height-var="--collapsible-panel-height"
        data-lb-width-var="--collapsible-panel-width"
        data-open={flag(@open)}
        data-closed={flag(not @open)}
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
