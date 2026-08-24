defmodule LiveShadcnTools.Gen.Slider do
  @moduledoc """
  The `slider` recipe: a value between two ends, chosen by dragging.

  ## Why it is not a form control

  The form-control recipe knows three shapes, and a slider is none of them: it
  is not checkable, not pressable, and its root is a `<div>`. What it is, is a
  native `<input type="range">` per thumb with a set of `<div>`s drawn where
  those inputs say — which Base UI documents in as many words, in the ref it
  publishes for "the nested input element".

  So the recipe writes the inputs and the hook draws. The input is what a
  reader drags, what a keyboard moves, what a screen reader announces and what
  a form submits, and every one of those is the platform's.

  ## One function, and one input per value

  A slider with two thumbs is a range, and the number of thumbs is the number
  of values the caller passed:

      <.slider id="price" name="price" value={[20, 80]} min={0} max={100} />

  Each input carries the same `name`, so the form reports a list. One value is
  one input and one thumb, which is the same component saying less.

  ## What the server knows

  Whatever the form tells it. There is no event of this component's own.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Spec

  @required %{
    root: "Root",
    control: "Control",
    track: "Track",
    indicator: "Indicator",
    thumb: "Thumb"
  }

  @doc "The attribute names the client hook owns rather than the server."
  def client_attributes, do: ~w(data-dragging data-focused data-touched)

  @doc "The module source for one component."
  def module(spec, opts) do
    roles = roles!(spec)
    name = String.replace(spec["name"], "-", "_")

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

      alias LiveBase.Slider

    #{function_doc(name)}
    #{declarations()}
      def #{name}(assigns) do
        ~H\"\"\"
    #{markup(spec, roles)}
        \"\"\"
      end

      defp flag(true), do: ""
      defp flag(_state), do: nil
    end
    """
  end

  defp roles!(spec) do
    Map.new(@required, fn {role, primitive} ->
      case find(spec["parts"], primitive) do
        nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a slider"
        found -> {role, found}
      end
    end)
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

  # The root's tree already nests the control, the track, the indicator and the
  # loop over thumbs, because shadcn's `Slider` assembles them. What the recipe
  # adds is the input inside each thumb — the control itself, which upstream
  # gets from Base UI and this has to write.
  defp markup(spec, roles) do
    tree =
      roles.root.part["tree"]
      |> Heex.with_children_at(Spec.key(roles.thumb.node))
      |> add_class_at(Spec.key(roles.indicator.node), "relative")

    Heex.render(tree, %{
      attrs: attributes(roles),
      props: props(spec, roles),
      children: input(),
      class: "@class",
      params: Map.get(roles.root.part, "params", %{}),
      # `_values` is what upstream resolved out of `value`, `defaultValue` and
      # the two ends, and it is what the loop over thumbs counts. Here the
      # caller passes the list, so that name is this component's `value`.
      bindings: %{"_values" => "@value"},
      contexts: Map.get(roles.root.part, "contexts", []),
      variants: spec["variants"] || %{},
      client_attributes: client_attributes(),
      hook_part: Spec.key(roles.root.node),
      rest: true
    })
  end

  # The hook sets the range width. Its positioning is part of that behaviour,
  # not a replacement over generated source.
  defp add_class_at(%{"module" => module, "part" => part} = node, key, class) do
    if "#{module}.#{part}" == key do
      Map.update(node, "class", class, fn current -> Enum.join([current, class], " ") end)
    else
      add_class_at_children(node, key, class)
    end
  end

  defp add_class_at(node, key, class) when is_map(node),
    do: add_class_at_children(node, key, class)

  defp add_class_at(node, _key, _class), do: node

  defp add_class_at_children(node, key, class) do
    Map.update(node, "children", [], fn children ->
      Enum.map(children, &add_class_at(&1, key, class))
    end)
  end

  # Invisible, and over its own thumb. `opacity: 0` rather than `hidden`,
  # because a hidden input takes no focus and answers no key.
  defp input do
    """
    <input
      type="range"
      id={Slider.input_id(@id, index)}
      name={@name}
      value={Enum.at(@value, index)}
      min={@min}
      max={@max}
      step={@step}
      disabled={@disabled}
      aria-label={@label}
      data-lb-slider-input
      class="absolute inset-0 size-full cursor-pointer opacity-0 disabled:cursor-not-allowed"
    />\
    """
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

  defp attributes(roles) do
    state = [
      {"data-orientation", :code, "@orientation"},
      {"data-disabled", :code, "flag(@disabled)"}
    ]

    %{
      Spec.key(roles.root.node) =>
        [
          {"id", :code, "@id"},
          {"phx-hook", :code, "Slider.hook()"},
          {"phx-mounted", :code, "Slider.owned_attributes()"}
        ] ++ state,
      Spec.key(roles.control.node) => state,
      Spec.key(roles.track.node) => state,
      Spec.key(roles.indicator.node) => [{"data-lb-slider-range", :bare} | state],
      # No `:for` here: upstream already writes one, over the values it resolved
      # into `_values`, and the recipe binds that name to the prop rather than
      # looping a second time over the same list.
      #
      # No `position` either. The hook sets `inset-inline-start` and a
      # `transform` on this element, and a rule that positioned it as well would
      # be two answers to where it is.
      Spec.key(roles.thumb.node) =>
        [
          {"data-index", :code, "index"},
          {"data-lb-slider-thumb", :bare},
          {"style", :text, "position: absolute"}
        ] ++ state
    }
  end

  defp declarations do
    """
      attr :id, :string, required: true, doc: "The hook needs one, and each input derives its own."
      attr :name, :string, default: nil, doc: "What the form submits every value under."

      attr :value, :list,
        default: [50],
        doc: "One value per thumb. Two make a range; the list's length is the number of thumbs."

      attr :min, :integer, default: 0
      attr :max, :integer, default: 100
      attr :step, :integer, default: 1
      attr :disabled, :boolean, default: false
      attr :label, :string, default: nil, doc: "Names each thumb to a screen reader."

      attr :orientation, :string,
        default: "horizontal",
        values: ["horizontal", "vertical"]

      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global
    """
  end

  defp function_doc(name) do
    ~s'''
      @doc """
      A value between two ends, chosen by dragging.

          <.#{name} id="price" name="price" value={[20, 80]} />

      One `<input type="range">` per thumb, drawn. The input is what a reader
      drags, what a keyboard moves, what a screen reader announces and what a
      form submits — so `phx-change` on the form around it reports the value
      the same way a text field does, and this component has no event of its
      own.
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
