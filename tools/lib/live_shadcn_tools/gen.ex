defmodule LiveShadcnTools.Gen do
  @moduledoc """
  Stage 3 of the pipeline: a spec becomes a HEEx module.

  The generator is deterministic. It reads `registry/spec/<name>.json`, picks
  the recipe the spec names, and writes the module. Running it twice on an
  unchanged spec produces identical bytes, which is what makes `--check` a
  usable CI gate and what makes a diff in generated output mean something.

  No model is involved. A recipe is written once by a person, reviewed, and
  then frozen.
  """

  alias LiveShadcnTools.Gen.Calendar
  alias LiveShadcnTools.Gen.Carousel
  alias LiveShadcnTools.Gen.Chart
  alias LiveShadcnTools.Gen.Checkbox
  alias LiveShadcnTools.Gen.Clipboard
  alias LiveShadcnTools.Gen.Dialog
  alias LiveShadcnTools.Gen.Disclosure
  alias LiveShadcnTools.Gen.FormControl
  alias LiveShadcnTools.Gen.Listbox
  alias LiveShadcnTools.Gen.Menu
  alias LiveShadcnTools.Gen.NavigationMenu
  alias LiveShadcnTools.Gen.Pagination
  alias LiveShadcnTools.Gen.Popover
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Gen.Progress
  alias LiveShadcnTools.Gen.RadioGroup
  alias LiveShadcnTools.Gen.Resizable
  alias LiveShadcnTools.Gen.Scroller
  alias LiveShadcnTools.Gen.Separator
  alias LiveShadcnTools.Gen.Sidebar
  alias LiveShadcnTools.Gen.Slider
  alias LiveShadcnTools.Gen.Switch
  alias LiveShadcnTools.Gen.Tabs
  alias LiveShadcnTools.Gen.Toast
  alias LiveShadcnTools.Gen.ToggleGroup

  @recipes %{
    "calendar" => Calendar,
    "chart" => Chart,
    "carousel" => Carousel,
    "checkbox" => Checkbox,
    "clipboard" => Clipboard,
    "dialog" => Dialog,
    "disclosure" => Disclosure,
    "form-control" => FormControl,
    "listbox" => Listbox,
    "menu" => Menu,
    "navigation-menu" => NavigationMenu,
    "pagination" => Pagination,
    "popover" => Popover,
    "progress" => Progress,
    "radio-group" => RadioGroup,
    "resizable" => Resizable,
    "presentational" => Presentational,
    "scroller" => Scroller,
    "separator" => Separator,
    "sidebar" => Sidebar,
    "slider" => Slider,
    "switch" => Switch,
    "tabs" => Tabs,
    "toggle-group" => ToggleGroup,
    "toast" => Toast
  }

  @doc "The recipes that have been written."
  def recipes, do: Map.keys(@recipes)

  @doc """
  The formatted module source for a spec.

  `:module` is the module name to generate under.
  """
  def module(spec, opts) do
    recipe = spec["recipe"]
    reachable!(spec)
    single_content!(spec)

    case Map.fetch(@recipes, recipe) do
      {:ok, implementation} ->
        spec
        |> implementation.module(opts)
        |> with_variants(spec)
        |> format()
        |> unique_ids!()

      :error ->
        {:error, recipe}
    end
  end

  # The `cva` tables, appended once the markup is written.
  #
  # Every recipe used to interpolate them into its own template, and the table
  # was worked out from the spec while the lookups were worked out from the
  # tree — two answers to one question, which disagreed wherever a recipe
  # renders a slice of a part rather than the whole. Reading the markup that
  # was actually written is the same question asked once.
  defp with_variants(source, spec) do
    case Presentational.variant_table(spec, source) do
      "" -> source
      table -> String.replace_suffix(source, "end\n", table <> "end\n")
    end
  end

  @doc """
  Refuses a module that renders the same element id twice.

  An id is unique on a page — the ARIA contract is built on that, and every
  `aria-controls` and `aria-labelledby` this pipeline emits names one. So a
  generated component that writes `id={@id}` twice has assembled something
  twice, and the second copy is a mistake wherever it came from.

  `chain-of-thought` came out with its whole self inside its own trigger. It
  compiled. Its snapshot was stable. What caught it was axe-core noticing a
  button with no text, three checks and one browser later, and nothing in that
  report said "this component contains itself".

  Asked of one function at a time. Two functions in a module each writing
  `id={@id}` are two components, each with one id — `input-group` has two
  because a group takes either an `<input>` or a `<textarea>` — and only a page
  that called both with the same id would have a duplicate, which is the
  caller's to avoid.
  """
  def unique_ids!({:ok, source}) do
    case source |> String.split(~r/^  def /m) |> Enum.flat_map(&repeated_ids/1) do
      [] ->
        {:ok, source}

      duplicated ->
        names =
          Enum.map_join(duplicated, ", ", fn {expression, count} -> "#{expression} × #{count}" end)

        raise """
        the same element id is rendered more than once: #{names}

        An id is unique on a page, and every `aria-controls` this pipeline emits \
        names one. Rendering it twice means the recipe assembled a part twice — \
        a component that contains itself, most likely.
        """
    end
  end

  def unique_ids!(other), do: other

  defp repeated_ids(body) do
    ~r/\bid=\{([^}]+)\}/
    |> Regex.scan(body, capture: :all_but_first)
    |> List.flatten()
    |> Enum.frequencies()
    |> Enum.filter(fn {_expression, count} -> count > 1 end)
  end

  @doc """
  Refuses a component that names a module the host application will not have.

  A component may call another component this pipeline generates, and inside
  one package that works. Across packages it cannot, and the reason is how the
  two packages ship:

    * `live_shadcn` is copied into the application by `mix ui.add`, which
      rewrites `LiveShadcn.UI.Button` to `MyAppWeb.Components.UI.Button`
    * `live_ai_elements` is an ordinary dependency, compiled once, with its
      module names fixed before the application is built

  So a compiled `LiveAiElements.Components.Reasoning` that calls
  `LiveShadcn.UI.Collapsible` names a module that does not exist: `mix ui.add`
  renamed it on the way in, and had no way to reach into a dependency and
  rename the call.

  The reference is real and upstream writes it, so the fix is not to drop it.
  It is to fold the referenced component's markup into this one, the way the
  spec already folds a Base UI part. Until the reader does that, a component
  that needs it is named here rather than generated wrong.
  """
  def reachable!(spec) do
    case Enum.uniq(foreign_refs(spec["parts"], spec)) do
      [] ->
        :ok

      components ->
        raise """
        #{spec["name"]} renders #{Enum.join(components, ", ")}, which #{other(spec["source"])} \
        generates into another package. A dependency cannot name a module that \
        `mix ui.add` renames on the way into an application, so the markup has \
        to be folded in rather than called.
        """
    end
  end

  defp foreign_refs(node, spec) when is_list(node),
    do: Enum.flat_map(node, &foreign_refs(&1, spec))

  defp foreign_refs(
         %{"type" => "component_ref", "source" => other, "component" => component} = node,
         %{"source" => source} = spec
       )
       when other != source do
    # A reference the reader left standing on purpose: the component it names
    # behaves, and nothing here can write that behaviour, so the part is dropped
    # and the moduledoc says what to compose instead. See
    # `LiveShadcnTools.carries?/2`.
    if LiveShadcnTools.carries?(spec["recipe"], node["recipe"]),
      do: ["#{other}/#{component}"],
      else: []
  end

  defp foreign_refs(node, spec) when is_map(node),
    do: node |> Map.values() |> Enum.flat_map(&foreign_refs(&1, spec))

  defp foreign_refs(_node, _spec), do: []

  defp other("ai_elements"), do: "the shadcn registry"
  defp other(_source), do: "AI Elements"

  @doc """
  Refuses a part that would render its content in two places.

  A part has one place its children go. A fold can produce two: shadcn's
  scroll-area puts `{children}` inside its viewport, and the AI Elements
  component that renders `<ScrollArea>` puts its own children inside the
  reference — so the marker arrives twice and every child is drawn twice.

  That is not a tidiness problem. `suggestion` rendered three buttons six
  times, in two different wrappers, and both copies looked plausible on their
  own. Nothing downstream would have caught it: the markup is valid, the
  snapshot is stable, and axe has no opinion about being shown a thing twice.

  Where the content belongs when a fold produces two is a decision the fold has
  to make, and it does not make it yet. Until it does, this says so.
  """
  def single_content!(spec) do
    doubled =
      for part <- spec["parts"] || [], markers(part["tree"]) > 1, do: part["name"]

    if doubled != [] do
      raise """
      #{Enum.join(doubled, ", ")} would render its content in more than one place.

      The fold left two `{children}` markers in one part, so everything the \
      caller passes is drawn twice. The fold has to choose which one the \
      content belongs in.
      """
    end
  end

  defp markers(%{"type" => "children"}), do: 1

  # A choice draws one branch or the other, never both, so a marker in each is
  # one marker and not two. `checkpoint` wraps its content in a tooltip when it
  # has one and renders it bare when it does not, which is the same content in
  # the same place under two conditions.
  defp markers(%{"type" => "choice"} = node),
    do: max(markers(node["then"]), markers(node["else"]))

  # The same for a table: one entry is drawn, whichever the key selects.
  defp markers(%{"type" => "lookup", "entries" => entries}),
    do: entries |> Enum.map(&markers(&1["node"])) |> Enum.max(fn -> 0 end)

  defp markers(node) when is_map(node), do: node |> Map.values() |> markers()
  defp markers(nodes) when is_list(nodes), do: Enum.sum(Enum.map(nodes, &markers/1))
  defp markers(_node), do: 0

  @doc "The module name a component is generated under."
  def module_name(namespace, name),
    do: Module.concat(namespace, name |> String.replace("-", "_") |> Macro.camelize())

  # Formatting is part of being deterministic. Two specs that differ only in
  # whitespace have to produce the same module, and a generated file that the
  # project formatter would rewrite is a file somebody will rewrite by hand.
  defp format(source) do
    formatted =
      source
      |> Code.format_string!(
        sigils: [H: &Phoenix.LiveView.HTMLFormatter.format/2],
        # The HEEx formatter reports parse errors against a file name.
        file: "generated.ex",
        line_length: 98
      )
      |> IO.iodata_to_binary()

    {:ok, formatted <> "\n"}
  end
end
