defmodule LiveShadcnTools.Gen.Clipboard do
  @moduledoc """
  The `clipboard` recipe: markup, and one button whose state the client owns.

  Two components are this: `snippet` and `environment-variables`. Both are
  presentational everywhere except one button, and both write the same three
  lines of React —

      const [isCopied, setIsCopied] = useState(false)
      await navigator.clipboard.writeText(text)
      const Icon = isCopied ? CheckIcon : CopyIcon

  ## Why the server is told none of it

  Copying is `navigator.clipboard.writeText`, which exists in a browser and
  nowhere else, so no assign can do it. What is left is a tick that replaces the
  copy icon for two seconds and then puts it back. Bound to an assign that costs
  a round trip and a server-side timer per copy, and makes every caller write
  `handle_event("copied", …)` and `Process.send_after` for an icon.

  So the recipe declares the condition client-owned, and
  `LiveShadcnTools.Gen.Heex` draws both icons — each marked with the state it
  belongs to, the one the client does not start in `hidden`. `LiveBase.Clipboard`
  writes to the clipboard and swaps which one is hidden, and
  `JS.ignore_attributes` keeps the next patch from putting the server's guess
  back.

  ## What the caller passes, and why the recipe knows it

  React reads the text to copy off a context, inside the click handler. The spec
  reader records what the *markup* reads, so a field read in a callback reaches
  no part — and a HEEx component has no context to read it from anyway. Upstream
  is the component above passing it down, so here it is a prop, the same answer
  phase 1a reached for `snippet_input`'s `code`.

  That the caller passes it is also the honest answer for a secret: a value the
  page was never given cannot be copied from the page, and whether to hand it
  over is the caller's decision rather than this component's.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Gen.Tree

  # `useState(false)`: the browser starts in the `else` branch, and the `then`
  # branch is the one drawn hidden.
  @state %{then: "copied", else: "idle", initial: "idle"}

  # What the button copies, per component: the attributes it declares, and the
  # expression that reads them. See the moduledoc for why the recipe holds this.
  @copies %{
    "snippet" => %{
      declare: [
        ~s|attr :code, :string, required: true, doc: "The text the button copies."|
      ],
      text: "@code"
    },
    "commit" => %{
      declare: [
        ~s|attr :hash, :string, required: true, doc: "The commit hash the button copies."|
      ],
      text: "@hash"
    },
    "code-block" => %{
      declare: [
        ~s|attr :code, :string, required: true, doc: "The code the button copies."|
      ],
      text: "@code"
    },
    "terminal" => %{
      declare: [
        ~s|attr :output, :string, required: true, doc: "The output the button copies."|
      ],
      text: "@output"
    },
    "stack-trace" => %{
      declare: [
        ~s|attr :raw, :string, required: true, doc: "The stack trace the button copies."|
      ],
      text: "@raw"
    },
    "environment-variables" => %{
      declare: [
        ~s|attr :name, :string, required: true, doc: "The variable's name."|,
        ~s|attr :value, :string, required: true, doc: "The variable's value."|
      ],
      # `copyFormat` is upstream's prop and upstream's three formats.
      text:
        ~S|Map.get(%{"name" => @name, "export" => "export #{@name}=\"#{@value}\""}, @copy_format, @value)|
    }
  }

  @doc "The module source for one component."
  def module(spec, opts) do
    part = copy_button!(spec)
    copies = Map.fetch!(@copies, spec["name"])

    spec
    |> switch(spec["name"])
    |> passing(part, copies)
    |> hooked(part, attributes(copies))
    |> Presentational.module(
      opts
      |> Keyword.put(:declare, declared(spec, part, copies))
      |> Keyword.put(:client_state, %{"isCopied" => @state})
    )
  end

  # On the copy button's node, and not through `:attrs`.
  #
  # `:attrs` in the context is keyed by the Base UI part a node draws, and both
  # of `terminal`'s buttons draw shadcn's `Button` — so the hook, the text and
  # the timeout landed on the clear button too, which then read an `@id` it had
  # never declared and raised on its first render.
  defp hooked(spec, button, attributes) do
    Map.update!(spec, "parts", fn parts ->
      Enum.map(parts, fn part ->
        if part["name"] == button["name"],
          do: Map.update!(part, "tree", &Heex.with_attrs(&1, attributes)),
          else: part
      end)
    end)
  end

  # What a part that *calls* the copy button has to hand it.
  #
  # `terminal` draws its own header when the caller gives no children, and that
  # header contains the copy button. Upstream can render it with no props
  # because the button reads the output off a context; here it takes the output
  # and an id, and a call that passes neither is a component that raises the
  # first time anybody renders it — which Phoenix says at compile time, and this
  # project builds with warnings as errors.
  #
  # So the call passes them, and the calling part takes them too: what it cannot
  # read from a context, it asks its own caller for. That is the same answer
  # every context in this registry gets.
  defp passing(spec, button, copies) do
    names = ["id" | Enum.map(copies.declare, &declared_name/1)]
    called = button["name"]

    Map.update!(spec, "parts", fn parts ->
      Enum.map(parts, fn part ->
        if part["name"] != called and calls?(part["tree"], called),
          do: part |> forward(called, names) |> asking(names),
          else: part
      end)
    end)
  end

  defp declared_name(declaration) do
    [name] = Regex.run(~r/^attr :([a-z_]+),/, declaration, capture: :all_but_first)
    name
  end

  defp calls?(%{"type" => "part_ref", "part" => part}, part), do: true

  defp calls?(node, part) when is_map(node),
    do: node |> Map.values() |> Enum.any?(&calls?(&1, part))

  defp calls?(nodes, part) when is_list(nodes), do: Enum.any?(nodes, &calls?(&1, part))
  defp calls?(_node, _part), do: false

  defp forward(part, button, names) do
    Map.update!(part, "tree", &pass(&1, button, names))
  end

  defp pass(%{"type" => "part_ref", "part" => button} = node, button, names) do
    Map.put(node, "attrs", Enum.map(names, &%{"name" => &1, "kind" => "code", "value" => &1}))
  end

  defp pass(node, button, names) when is_map(node),
    do: Map.new(node, fn {key, value} -> {key, pass(value, button, names)} end)

  defp pass(nodes, button, names) when is_list(nodes),
    do: Enum.map(nodes, &pass(&1, button, names))

  defp pass(value, _button, _names), do: value

  # A prop the part now reads, so that the generator resolves the name and
  # declares it. A name upstream already destructured keeps its own default.
  defp asking(part, names) do
    Map.update(part, "params", %{}, fn params ->
      Map.merge(Map.new(names, &{&1, nil}), params)
    end)
  end

  # `environment-variables` folds `shadcn/switch`, and a fold copies markup
  # rather than behaviour: what arrived was a `<span>` with the switch's class
  # string, React's `checked` prop written out as an HTML attribute, and no
  # `role`, no `tabindex` and no `aria-checked`. axe reports that, and is right
  # to — a span nobody can reach is not a switch.
  #
  # So the recipe writes the switch's contract over the folded markup. Not the
  # shadcn switch's own behaviour, which toggles a hidden input on the client:
  # this one reveals a secret, so it asks the server, which is the trade phase 1
  # stated. The switch recipe's attributes and this recipe's event are the same
  # contract read from two sides.
  defp switch(spec, "environment-variables") do
    spec
    # React's prop, not markup. A `<span>` has no `checked`.
    |> Tree.drop_attr_at_slot("switch", "checked")
    |> Tree.put_attrs_at_slot("switch", [
      {"role", :text, "switch"},
      {"tabindex", :text, "0"},
      # A word, not a presence: Tailwind compiles `aria-checked:` to
      # `[aria-checked="true"]`, and ARIA defines no empty value.
      {"aria-checked", :code, "to_string(@show_values == true)"},
      {"phx-click", :code, "@on_toggle"},
      # A switch answers the space bar wherever it is drawn, and this one is
      # drawn as a `<span>` — the element shadcn's class string is written for.
      {"phx-keydown", :code, "@on_toggle"},
      {"phx-key", :text, " "},
      # Present or absent, and empty when present — which is how Base UI marks
      # state and what every other generated component writes.
      {"data-checked", :code, ~s|if(@show_values == true, do: "")|},
      {"data-unchecked", :code, ~s|if(@show_values != true, do: "")|}
    ])
    |> Tree.put_attrs_at_slot("switch-thumb", [
      # Present or absent, and empty when present — which is how Base UI marks
      # state and what every other generated component writes.
      {"data-checked", :code, ~s|if(@show_values == true, do: "")|},
      {"data-unchecked", :code, ~s|if(@show_values != true, do: "")|}
    ])
  end

  defp switch(spec, _name), do: spec

  # What the caller has to supply that upstream never destructured.
  defp declared(spec, part, copies) do
    %{part["name"] => declarations(part, copies)}
    |> Map.merge(toggle_declaration(spec["name"]))
  end

  defp toggle_declaration("environment-variables") do
    %{
      "environment_variables_toggle" => [
        ~s|attr :on_toggle, :any,| <>
          ~s| default: nil,| <>
          ~s| doc: "Pushed when the switch is flipped. The server owns `show_values`, because the value it reveals is a secret."|
      ]
    }
  end

  defp toggle_declaration(_name), do: %{}

  @doc """
  The state the client owns, named on both sides of the choice.

  The hook reads these names off `data-lb-state`, so it and the recipe have to
  agree about them.
  """
  def state, do: @state

  # The one part that copies. A component with two of them, or none, is not this
  # recipe's shape, and saying so beats generating a button that does nothing.
  defp copy_button!(spec) do
    case Enum.filter(spec["parts"], &copies?(&1["tree"])) do
      [part] ->
        part

      parts ->
        raise """
        #{spec["name"]} has #{length(parts)} parts that choose on `isCopied`, and the \
        clipboard recipe writes one button. Either the component is not this shape, \
        or the recipe has to say which of them the hook belongs on.
        """
    end
  end

  defp copies?(%{"type" => "choice", "when" => "isCopied"}), do: true
  defp copies?(node) when is_map(node), do: node |> Map.values() |> Enum.any?(&copies?/1)
  defp copies?(nodes) when is_list(nodes), do: Enum.any?(nodes, &copies?/1)
  defp copies?(_node), do: false

  defp declarations(part, copies) do
    ([~s|attr :id, :string, required: true, doc: "The hook needs one to be found by."|] ++
       copies.declare)
    |> Enum.reject(&already_declared?(&1, part))
  end

  # What upstream destructured, the recipe does not declare again. `commit`
  # takes its `hash` as a prop and `snippet` reads its `code` off a context, so
  # one of the two already has the attribute and Phoenix refuses the second.
  defp already_declared?(declaration, part) do
    declared = Map.keys(Map.get(part, "params") || %{}) |> Enum.map(&LiveShadcnTools.assign/1)

    case Regex.run(~r/^attr :([a-z_][a-z_0-9]*)/, declaration, capture: :all_but_first) do
      [name] -> name in declared
      nil -> false
    end
  end

  defp attributes(copies) do
    [
      {"id", :code, "@id"},
      {"phx-hook", :code, "LiveBase.Clipboard.hook()"},
      {"phx-mounted", :code, "LiveBase.Clipboard.owned_attributes()"},
      {"data-lb-clipboard", :code, copies.text},
      # Upstream's `timeout` prop, in the browser that runs the timer.
      {"data-lb-timeout", :code, "@timeout"}
    ]
  end
end
