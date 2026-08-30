defmodule LiveAiElements.Components.Reasoning do
  @moduledoc """
  Reasoning. Built on `shadcn/collapsible`.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.

  | Upstream | Digest |
  |---|---|
  | `ai_elements/reasoning.tsx` | `f138cddde358` |
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/anonymous/class/0" => "not-prose mb-4",
    "jsx/anonymous/class/1" =>
      "flex w-full items-center gap-2 text-muted-foreground text-sm transition-colors hover:text-foreground",
    "jsx/anonymous/class/2" => "size-4",
    "jsx/anonymous/class/3" => "size-4 transition-transform",
    "jsx/anonymous/class/4" => "rotate-180",
    "jsx/anonymous/class/5" => "rotate-0",
    "port/class/0" =>
      "mt-4 text-sm data-[state=closed]:fade-out-0 data-[state=closed]:slide-out-to-top-2 data-[state=open]:slide-in-from-top-2 text-muted-foreground outline-none data-[state=closed]:animate-out data-[state=open]:animate-in"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  alias LiveBase.Disclosure

  @doc """
  Built on `shadcn/collapsible`.

      <.reasoning id="details" title="Show details">
        The panel body.
      </.reasoning>

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
  attr(:content, :any, default: nil)
  slot(:get_thinking_message)

  def reasoning(assigns) do
    ~H"""
    <div
      data-slot={@rest[:"data-slot"] || "collapsible"}
      id={@id}
      data-open={flag(@open)}
      data-closed={flag(not @open)}
      open={@open}
      class={[upstream_fact("jsx/anonymous/class/0"), (@class || "")]}
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
        class={[
          "group",
          upstream_fact("jsx/anonymous/class/1"),
          (@trigger_class || "")
        ]}
      >
        <%= if @title in [nil, ""] do %>
          <LiveShadcn.Icon.icon name="brain" class={upstream_fact("jsx/anonymous/class/2")} />{render_slot(@get_thinking_message)}<LiveShadcn.Icon.icon
            name="chevron-down"
            class={[
              upstream_fact("jsx/anonymous/class/3"),
              "group-data-panel-open:rotate-180",
              if(@open,
                do: upstream_fact("jsx/anonymous/class/4"),
                else: upstream_fact("jsx/anonymous/class/5")
              )
            ]}
          />
        <% end %>
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
        class={[
          upstream_fact("port/class/0"),
          (@content_class || "")
        ]}
      >
        <LiveAiElements.Markdown.markdown content={@content} />
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
