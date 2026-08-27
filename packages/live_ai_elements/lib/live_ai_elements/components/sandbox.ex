defmodule LiveAiElements.Components.Sandbox do
  @moduledoc """
  Sandbox.

  Upstream exports 7 more parts, each a thin
  wrapper around a part of `<.collapsible>`, `<.tabs>`. That component is one
  function here — its parts have to agree about which one they belong to,
  and an id repeated is an id to mistype — so it is what to compose inside
  this, and there is nothing for the wrappers to wrap.

  Reviewed from upstream. The marked upstream fact block is synchronized.
  The HEEx body is maintained as a LiveView port.
  """

  use Phoenix.Component

  # live-shadcn: upstream facts start
  @upstream_facts %{
    "jsx/SandboxTabsBar/class/0" => "flex w-full items-center border-border border-t border-b"
  }
  # live-shadcn: upstream facts end
  Module.get_attribute(__MODULE__, :upstream_facts)

  defp upstream_fact(key), do: Map.fetch!(@upstream_facts, key)

  @doc "The `sandbox_tabs_bar` part."

  attr(:class, :any, default: nil, doc: "Appended to the class string upstream renders.")
  attr(:rest, :global, include: ["data-slot"])
  slot(:inner_block)

  def sandbox_tabs_bar(assigns) do
    ~H"""
    <div class={[upstream_fact("jsx/SandboxTabsBar/class/0"), (@class || "")]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
