defmodule LiveShadcnTools.Gen.Scroller do
  @moduledoc """
  The `scroller` recipe: a box that scrolls, with a scrollbar the style sheet
  can reach.

  ## Why every attribute is the client's

  The other recipes here split the work: a `Phoenix.LiveView.JS` command says
  what happens, and a hook does the one thing a command cannot. A scroll area
  has nothing to split. How much there is to scroll, how far down the reader is,
  how tall the thumb should be — each is a measurement, the server has none of
  them, and there is no decision left over.

  So the recipe places the hook, marks the two elements it has to find, and
  leaves every documented attribute to it. `LiveBase.Scroller` writes them.

  ## One function

  A scroll area is a root, a viewport, a scrollbar and a thumb, and a caller
  composes none of them: they are four elements that have to agree about one
  measurement. So the recipe folds them, and the caller writes what scrolls.

      <.scroll_area id="log" class="h-72">
        <p :for={line <- @lines}>{line}</p>
      </.scroll_area>

  ## What the hook has to find

  Two markers, both plumbing between this recipe and that hook, and neither read
  by a shadcn class string:

    * `data-lb-scroller` on the viewport — the element that actually scrolls
    * `data-lb-thumb` on each thumb — so dragging one scrolls the viewport
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Spec

  @required %{root: "Root", viewport: "Viewport"}

  # A scrollbar the component draws itself, and the thumb inside it. Base UI's
  # scroll area has both and hides the platform's; `use-stick-to-bottom`, which
  # is what `conversation` scrolls with, has neither and lets the platform draw
  # its own. Both are scrollers — a box that scrolls, with the hook that
  # measures it — and only one of them has a bar to place.
  @optional %{scrollbar: "Scrollbar", thumb: "Thumb"}

  @doc """
  The attribute names the client hook owns rather than the server.

  All of them. See the moduledoc.
  """
  def client_attributes do
    ~w(data-has-overflow-x data-has-overflow-y data-overflow-x-start data-overflow-x-end
       data-overflow-y-start data-overflow-y-end data-scrolling data-hovering)
  end

  @doc "The module source for one component."
  def module(spec, opts) do
    if spec["name"] == "message-scroller" do
      message_scroller_module(spec, opts)
    else
      roles = roles!(spec)
      name = String.replace(spec["name"], "-", "_")

      """
      defmodule #{inspect(Keyword.fetch!(opts, :module))} do
      #{moduledoc(spec)}

        use Phoenix.Component

        alias LiveBase.Scroller

      #{function_doc(spec, name)}
      #{declarations()}
        def #{name}(assigns) do
          ~H\"\"\"
      #{markup(spec, roles)}
          \"\"\"
        end
      end
      """
    end
  end

  # Message scroller uses the platform scrollbar, unlike scroll area. Its
  # independently exported viewport still benefits from the existing hook:
  # it measures scrolling state and keeps the data attributes its classes read.
  defp message_scroller_module(spec, opts) do
    viewport = Enum.find(spec["parts"], &(&1["name"] == "message_scroller_viewport"))

    spec
    |> Presentational.module(
      opts
      |> Keyword.put(:declare, %{
        viewport["name"] => [
          ~s|attr :id, :string, required: true, doc: "The hook needs one to be found by."|
        ]
      })
      |> Keyword.put(:attrs, %{
        Spec.key(viewport["tree"]) => [
          {"id", :code, "@id"},
          {"data-lb-scroller", :bare},
          # A message list opens at the newest message. Upstream reaches that
          # with `use-stick-to-bottom`; the React reference starts scrolled to
          # the end and ours started at the top, which parity reported as every
          # item being 418px out.
          {"data-lb-stick-to-bottom", :bare},
          # A box with more content than fits, and no way for a keyboard to
          # reach the rest of it. axe reports that as
          # `scrollable-region-focusable`, and it reported it here: the scroll
          # area's viewport has carried `tabindex` all along and this one did
          # not, because the two take different paths through this recipe.
          {"tabindex", :text, "0"},
          {"phx-hook", :code, "LiveBase.Scroller.hook()"},
          {"phx-mounted", :code, "LiveBase.Scroller.owned_attributes()"}
        ]
      })
    )
  end

  defp roles!(spec) do
    required =
      Map.new(@required, fn {role, primitive} ->
        case find(spec["parts"], primitive) do
          nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a scroll area"
          found -> {role, found}
        end
      end)

    optional =
      for {role, primitive} <- @optional,
          found = find(spec["parts"], primitive),
          into: %{},
          do: {role, found}

    Map.merge(required, optional)
  end

  defp find(parts, primitive) do
    Enum.find_value(parts, fn part ->
      case locate(part["tree"], primitive) do
        nil -> nil
        node -> %{node: node, part: part}
      end
    end)
  end

  defp locate(%{"part" => primitive} = node, primitive), do: node

  defp locate(node, primitive),
    do: node |> Map.get("children") |> List.wrap() |> Enum.find_value(&locate(&1, primitive))

  # ---- markup ----

  # The viewport, when the root does not already contain it.
  #
  # shadcn's `ScrollArea` assembles its own anatomy, so the root's tree nests
  # the viewport and the scrollbar and there is nothing to do. `conversation`
  # does not: upstream exports `<Conversation>` and `<ConversationContent>` as
  # two components and expects a caller to put one inside the other. Folded into
  # one function, this recipe is that caller — and a root with no viewport in it
  # is a component whose children have nowhere to go, which is what it drew.
  defp nesting(tree, roles) do
    if contains?(tree, Spec.key(roles.viewport.node)),
      do: tree,
      else: Map.put(tree, "children", [roles.viewport.part["tree"]])
  end

  defp contains?(node, key) when is_map(node) do
    Spec.key(node) == key or
      node |> Map.get("children") |> List.wrap() |> Enum.any?(&contains?(&1, key))
  end

  defp contains?(_node, _key), do: false

  # The root's own tree already nests the viewport, the scrollbar and the
  # corner, because shadcn's `ScrollArea` assembles them. The recipe places the
  # hook on the root and the markers inside it, and renders the tree as written.
  defp markup(spec, roles) do
    tree =
      roles.root.part["tree"]
      |> nesting(roles)
      |> Heex.with_children_at(Spec.key(roles.viewport.node))
      |> only_root_takes(Spec.key(roles.root.node))

    Heex.render(tree, %{
      attrs: attributes(roles),
      # `orientation` is a prop Base UI's scrollbar takes, not an attribute a
      # `<div>` has. Written out, it named a prop on an element.
      props: props(spec, roles),
      children: "{render_slot(@inner_block)}",
      class: "@class",
      # Every role's props, because every role is folded into this one
      # function. `orientation` belongs to the scrollbar and is read where the
      # scrollbar is drawn, which is inside the root's own tree.
      params:
        Enum.reduce(roles, %{}, fn {_role, %{part: part}}, all ->
          Map.merge(all, Map.get(part, "params", %{}))
        end),
      contexts: Map.get(roles.root.part, "contexts", []),
      variants: spec["variants"] || %{},
      # A scroll area's scrollbar is one of its own parts, so the reference to
      # it is rendered in place rather than calling a function nothing writes.
      # Through here rather than through the tree, which is why it needs the
      # same answer about what the caller reaches.
      parts:
        Map.new(spec["parts"], fn part ->
          {part["name"], only_root_takes(part, Spec.key(roles.root.node))}
        end),
      client_attributes: client_attributes(),
      hook_part: Spec.key(roles.root.node),
      rest: true
    })
  end

  defp props(spec, roles) do
    Map.new(roles, fn {_role, %{node: node}} ->
      names =
        spec
        |> get_in(["primitives", Spec.key(node), "props"])
        |> List.wrap()
        |> Enum.map(& &1["name"])

      {Spec.key(node), names}
    end)
  end

  # The caller's class and the caller's attributes reach the root and stop
  # there. Upstream exports the scrollbar separately, so it takes a `className`
  # and forwards its props; folded, it is inside the one component the caller
  # addresses, and `@class` on both put the caller's class in two places.
  defp only_root_takes(node, root) when is_map(node) do
    node
    |> Map.new(fn {key, value} -> {key, only_root_takes(value, root)} end)
    |> then(fn node ->
      if Map.has_key?(node, "merges_class") and Spec.key(node) != root,
        do: Map.merge(node, %{"merges_class" => false, "props" => false}),
        else: node
    end)
  end

  defp only_root_takes(nodes, root) when is_list(nodes),
    do: Enum.map(nodes, &only_root_takes(&1, root))

  defp only_root_takes(value, _root), do: value

  defp attributes(roles) do
    %{
      Spec.key(roles.root.node) => [
        {"id", :code, "@id"},
        {"phx-hook", :code, "Scroller.hook()"},
        {"phx-mounted", :code, "Scroller.owned_attributes()"}
      ],
      Spec.key(roles.viewport.node) => [
        {"data-lb-scroller", :bare},
        {"tabindex", :text, "0"},
        # What Base UI applies itself, and shadcn therefore never writes in a
        # class string. Without it the viewport has more content than fits and
        # no way to reach it: `overflow` is what makes a box a scrolling box.
        #
        # `scrollbar-width: none` only where the component draws a scrollbar of
        # its own, because the platform's beside it would be two. A scroller
        # with no bar of its own keeps the platform's, which is the only one it
        # has.
        {"style", :text, viewport_style(roles)}
      ]
    }
    |> Map.merge(bar(roles))
  end

  defp viewport_style(roles) do
    if Map.has_key?(roles, :scrollbar),
      do: "overflow: scroll; scrollbar-width: none",
      else: "overflow: auto"
  end

  defp bar(roles) when not is_map_key(roles, :scrollbar) or not is_map_key(roles, :thumb), do: %{}

  defp bar(roles) do
    %{
      Spec.key(roles.scrollbar.node) => [
        {"data-orientation", :code, "@orientation"},
        {"style", :code,
         ~s|if(@orientation == "horizontal", do: "position: absolute; inset-inline: 0; inset-block-end: 0", else: "position: absolute; inset-block: 0; inset-inline-end: 0")|}
      ],
      Spec.key(roles.thumb.node) => [
        {"data-lb-thumb", :bare},
        {"data-orientation", :code, "@orientation"},
        {"style", :code,
         ~s|if(@orientation == "horizontal", do: "flex: none; width: var(--scroll-area-thumb-width); height: 100%", else: "flex: none; width: 100%; height: var(--scroll-area-thumb-height)")|}
      ]
    }
  end

  defp declarations do
    """
      attr :id, :string, required: true, doc: "The hook needs one to be found by."

      attr :orientation, :string,
        default: "vertical",
        values: ["vertical", "horizontal"],
        doc: "Which way the scrollbar runs."

      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global
      slot :inner_block, required: true, doc: "What scrolls."
    """
  end

  defp function_doc(spec, name) do
    ~s'''
      @doc """
      #{Heex.summary(spec)}

          <.#{name} id="log" class="h-72">
            <p :for={line <- @lines}>{line}</p>
          </.#{name}>

      The scrollbar is drawn rather than the platform's, so a style sheet can
      reach it. Everything that takes is a measurement — how much there is to
      scroll, how far down the reader is, how tall the thumb should be — and
      every one of them is made in the browser. The server is told none of it.
      """
    '''
  end

  defp moduledoc(spec) do
    """
      @moduledoc \"\"\"
      #{Heex.headline(spec)}

      Generated by `mix ui.gen` from `#{Heex.spec_ref(spec)}`. Every
      class string, every `data-slot`, and every data attribute below came from
      upstream. Change the spec or the recipe, not this file.
      \"\"\"\
    """
  end
end
