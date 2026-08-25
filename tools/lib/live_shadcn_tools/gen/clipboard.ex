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

  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Gen.Tree
  alias LiveShadcnTools.Spec

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
    |> Presentational.module(
      opts
      |> Keyword.put(:declare, declared(spec, part, copies))
      |> Keyword.put(:attrs, %{Spec.key(part["tree"]) => attributes(copies)})
      |> Keyword.put(:client_state, %{"isCopied" => @state})
    )
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
    %{part["name"] => declarations(copies)}
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

  defp declarations(copies) do
    [~s|attr :id, :string, required: true, doc: "The hook needs one to be found by."|] ++
      copies.declare
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
