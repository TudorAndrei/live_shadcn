defmodule LiveAiElements.Components.Sources do
  @moduledoc """
  Sources. Built on `shadcn/collapsible`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.

  | Upstream | Digest |
  |---|---|
  | `ai_elements/sources.tsx` | `1454af3ac2c5` |
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/Source/class/0" => "flex items-center gap-2",
    "jsx/Source/class/1" => "h-4 w-4",
    "jsx/Sources/class/0" => "not-prose mb-4 text-primary text-xs",
    "jsx/SourcesTrigger/class/1" => "font-medium",
    "port/class/0" =>
      "mt-3 flex w-fit flex-col gap-2 data-[state=closed]:fade-out-0 data-[state=closed]:slide-out-to-top-2 data-[state=open]:slide-in-from-top-2 outline-none data-[state=closed]:animate-out data-[state=open]:animate-in"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Disclosure

  @doc """
  Built on `shadcn/collapsible`.

      <.sources id="details" title="Show details">
        The panel body.
      </.sources>

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
  attr(:count, :any, default: nil)

  def sources(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "collapsible"}
      id={@id}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      class={[upstream_fact("jsx/Sources/class/0"), (@class || "")]}
      {Map.drop(@rest, [:"data-slot"])}
    >
      <button
        data-slot="collapsible-trigger"
        id={Disclosure.trigger_id(@id)}
        type="button"
        aria-expanded={to_string(@open)}
        aria-controls={Disclosure.panel_id(@id)}
        phx-click={interactive(@disabled, Disclosure.toggle(item: @id, root: @id, multiple: true))}
        phx-mounted={Disclosure.owned_attributes(:trigger)}
        data-panel-open={flag(@open)}
        class={[upstream_fact("jsx/Source/class/0"), (@trigger_class || "")]}
      >
        <%= if @title in [nil, ""] do %>
          <p class={upstream_fact("jsx/SourcesTrigger/class/1")}>
            Used {@count} sources
          </p>
          <LiveShadcn.Icon.icon name="chevron-down" class={upstream_fact("jsx/Source/class/1")} />
        <% end %>
        {@title}
      </button>
      <div
        data-slot="collapsible-content"
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
        class={[
          upstream_fact("port/class/0"),
          (@content_class || "")
        ]}
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
