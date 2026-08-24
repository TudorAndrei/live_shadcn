defmodule LiveShadcnTools.Gen.Sidebar do
  @moduledoc """
  The `sidebar` recipe: a navigation panel that collapses.

  ## Why it is not a disclosure

  It looks like one. A trigger opens a panel, and the disclosure recipe exists
  for exactly that. But shadcn's sidebar draws twenty-three parts and not one
  Base UI primitive: every part is a plain `<div>`, `<ul>` or `<button>` with a
  class string, and the disclosure recipe finds its roles by the Base UI part
  each wraps. There is nothing here for it to find.

  What the sidebar has instead of a primitive is an attribute. `data-state` is
  `expanded` or `collapsed`, and every width, offset and cursor shadcn writes
  reads it through the group it sits on — `group-data-[collapsible=icon]:w-…`,
  `group-data-[collapsible=offcanvas]:w-0`. So twenty of the parts are markup
  the presentational recipe already knows how to write, and three of them are
  the ones this recipe has something to say about.

  ## The three

  | Part | What this adds |
  |---|---|
  | `sidebar` | the id, the state attributes, and the fact that the client owns them |
  | `sidebar_trigger` | the command that flips them |
  | `sidebar_rail` | the same command, on the strip down the edge |

  A trigger is not inside the sidebar it opens — it sits in a header across the
  page — so it is given the sidebar's id rather than folded into it. That is the
  one place this recipe asks the caller for something upstream did not:

      <.sidebar id="nav" collapsible="icon">…</.sidebar>
      <.sidebar_trigger for="nav" collapsible="icon" />

  React reaches the same fact through a context, which HEEx does not have.

  ## What is not generated

  Upstream's `Sidebar` returns early twice before the markup this reads: once
  for `collapsible="none"`, which is a panel that never collapses, and once for
  a narrow window, which renders the whole sidebar as a `Sheet` instead. The
  reader takes the last return, which is the general case; the two early ones
  are shapes a caller composes for themselves out of parts that already
  generate.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational

  # The parts this recipe has something to say about. Everything else is markup.
  @behaving ~w(sidebar sidebar_trigger sidebar_rail)

  # `SidebarMenuButton` returns its button bare, and returns it inside a tooltip
  # when it was given one. The reader takes the last return, which is the
  # tooltip, and a tooltip is one folded function here rather than the three
  # parts React composes — so the wrapper names `tooltip_content`, which no
  # module defines.
  #
  # The button is what the part is. A caller who wants a tooltip around it
  # writes one, which is what `<.tooltip>` is for and one line either way.
  @unwrapped %{"sidebar_menu_button" => "sidebar-menu-button"}

  @doc "The module source for one component."
  def module(spec, opts) do
    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

      alias LiveBase.Sidebar

    #{Enum.map_join(spec["parts"], "\n", &function(&1, spec))}end
    """
  end

  defp function(%{"name" => name} = part, spec) when name in @behaving,
    do: behaving(part, spec)

  defp function(part, spec), do: part |> unwrap() |> Presentational.function(spec)

  defp unwrap(%{"name" => name} = part) do
    with slot when is_binary(slot) <- Map.get(@unwrapped, name),
         node when is_map(node) <- slotted(part["tree"], slot) do
      Map.put(part, "tree", node)
    else
      _whole -> part
    end
  end

  defp slotted(%{"slot" => slot} = node, slot), do: node

  defp slotted(node, slot) when is_map(node),
    do: node |> Map.get("children") |> List.wrap() |> Enum.find_value(&slotted(&1, slot))

  defp slotted(_node, _slot), do: nil

  defp behaving(part, spec) do
    name = part["name"]

    """
    #{doc(name)}
    #{declarations(name)}
      def #{name}(assigns) do
        ~H\"\"\"
    #{markup(part, spec)}
        \"\"\"
      end
    """
  end

  defp markup(part, spec) do
    tree =
      part["tree"]
      |> Heex.with_children()
      |> Heex.with_attrs(attributes(part["name"]))

    Heex.render(tree, %{
      attrs: %{},
      children: "{render_slot(@inner_block)}",
      class: "@class",
      params: Map.get(part, "params", %{}),
      contexts: Map.get(part, "contexts", []),
      variants: spec["variants"] || %{},
      client_attributes: [],
      hook_part: nil,
      rest: true
    })
  end

  # The panel. `data-collapsible` carries the collapse mode while collapsed and
  # nothing while expanded, which is upstream's own
  # `state === "collapsed" ? collapsible : ""` said in HEEx.
  defp attributes("sidebar") do
    [
      {"id", :code, "@id"},
      {"data-state", :code, ~s|if(@open, do: "expanded", else: "collapsed")|},
      {"data-collapsible", :code, ~s|if(@open, do: "", else: @collapsible)|},
      {"data-side", :code, "@side"},
      {"data-variant", :code, "@variant"},
      {"phx-mounted", :code, "Sidebar.owned_attributes(:sidebar)"}
    ]
  end

  defp attributes(name) when name in ~w(sidebar_trigger sidebar_rail) do
    [
      {"data-lb-sidebar", :code, "@for"},
      {"aria-expanded", :code, "to_string(@open)"},
      {"phx-click", :code, "Sidebar.toggle(sidebar: @for, collapsible: @collapsible)"},
      {"phx-mounted", :code, "Sidebar.owned_attributes(:trigger)"}
    ]
  end

  defp declarations("sidebar") do
    """
      attr :id, :string, required: true, doc: "What a trigger names to open it."
      attr :open, :boolean, default: true, doc: "Whether it starts expanded."
      attr :side, :string, default: "left", values: ["left", "right"]
      attr :variant, :string, default: "sidebar", values: ["sidebar", "floating", "inset"]

      attr :collapsible, :string,
        default: "offcanvas",
        values: ["offcanvas", "icon"],
        doc: "What is left behind when it collapses: a strip of icons, or nothing."

      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global
      slot :inner_block
    """
  end

  defp declarations(name) when name in ~w(sidebar_trigger sidebar_rail) do
    """
      attr :for, :string, required: true, doc: "The id of the sidebar this opens."
      attr :open, :boolean, default: true, doc: "Whether that sidebar starts expanded."

      attr :collapsible, :string,
        default: "offcanvas",
        values: ["offcanvas", "icon"],
        doc: "The same value the sidebar was given."

      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global
      slot :inner_block
    """
  end

  defp doc("sidebar") do
    ~S'''
      @doc """
      A navigation panel that collapses.

          <.sidebar id="nav" collapsible="icon">
            <.sidebar_content>…</.sidebar_content>
          </.sidebar>

      Collapsing and expanding runs entirely on the client. The server is not
      told, and does not need to be: whether a reader has the navigation open
      is a fact about their window rather than about the application's data.
      """
    '''
  end

  defp doc("sidebar_trigger") do
    ~S'''
      @doc """
      The button that collapses and expands a sidebar.

          <.sidebar_trigger for="nav" collapsible="icon" />

      It names the sidebar rather than sitting inside it, because it does not:
      a trigger belongs in the header across the top of the page. React reaches
      the same fact through a context, which HEEx does not have.
      """
    '''
  end

  defp doc("sidebar_rail") do
    ~S'''
      @doc """
      The strip down the sidebar's edge, which does what the trigger does.

      It is `tabindex="-1"` and named for a screen reader, because it is a
      second way to reach a control that already has a first one.
      """
    '''
  end

  defp moduledoc(spec) do
    """
      @moduledoc \"\"\"
      #{Heex.headline(spec)}

      Generated by `mix ui.gen` from `#{Heex.spec_ref(spec)}`. Every
      class string and every `data-slot` below came from upstream. Change the
      spec or the recipe, not this file.
      \"\"\"\
    """
  end
end
