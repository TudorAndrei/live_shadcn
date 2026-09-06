defmodule StorybookWeb.Docs do
  @moduledoc """
  What a component's documentation page is made of.

  Three things go on that page, and none of them is typed by a person. That is
  the same rule the rest of this repository follows: if a fact is written twice,
  one of the copies is going to be wrong, and nothing will say which.

  | On the page | Where it comes from |
  |---|---|
  | the navigation | `StorybookWeb.Examples.components/0`, grouped by the sections in `registry/UPSTREAM.json` |
  | the Code tab | the `~H` body of the example function, read from source |
  | the API table | the component module's own `__components__/0` |

  ## Reading the example's source

  An example is a function, and what a reader wants to see is the markup inside
  it — the thing they would type. Elixir can hand that over exactly:
  `Code.string_to_quoted/2` parses `examples.ex`, and a `~H` sigil node carries
  its own body. No line arithmetic and no regular expression, which is the same
  argument the spec reader makes about `.tsx`.

  It happens once, at compile time. `@external_resource` means an edit to
  `examples.ex` recompiles this module, so the page cannot show markup that the
  example no longer has.

  ## Reading the API

  `Phoenix.Component` records every `attr` and `slot` a module declares, and
  hands them back through `__components__/0`: the name, the type, whether it is
  required, its `:doc`, and the `:default` and `:values` it was declared with.
  Slots carry their own attributes, each with a doc of its own.

  shadcn's website writes that table by hand. Here a component that gains an
  attribute gains a row, and one that loses an attribute loses one.
  """

  alias StorybookWeb.Examples

  @examples_path Path.join(__DIR__, "examples.ex")
  @external_resource @examples_path

  @upstream_path Path.expand("../../../registry/UPSTREAM.json", __DIR__)
  @external_resource @upstream_path

  @verify_path Path.expand("../../../registry/VERIFY.json", __DIR__)
  @external_resource @verify_path

  @policy_path Path.expand("../../../registry/VERIFICATION_POLICY.json", __DIR__)
  @external_resource @policy_path

  @spec_root Path.expand("../../../registry/spec", __DIR__)
  @snapshot_index_path Path.expand("../../../registry/snapshot/index.json", __DIR__)
  @official_examples_path Path.expand("../../../parity/official-examples.json", __DIR__)
  @repo_root Path.expand("../../..", __DIR__)
  @spec_paths Path.wildcard(Path.join(@spec_root, "*/*.json"))
  @snapshot_paths @snapshot_index_path
                  |> File.read!()
                  |> Jason.decode!()
                  |> Enum.flat_map(fn {key, examples} ->
                    Enum.map(
                      examples,
                      &Path.join(Path.dirname(@snapshot_index_path), "#{key}-#{&1}.html")
                    )
                  end)
  @parity_example_paths Path.expand("../../../parity/src/examples/*.tsx", __DIR__)
                        |> Path.wildcard()
  @ai_source_paths ["ai_elements", "ai_examples"]
                   |> Enum.flat_map(fn directory ->
                     Path.expand("../../../registry/upstream/#{directory}/*.tsx", __DIR__)
                     |> Path.wildcard()
                   end)

  @verification_rule_paths LiveShadcnVerification.collect_verification_rules(@repo_root)
                           |> Enum.map(fn {relative, _content} ->
                             Path.join(@repo_root, relative)
                           end)

  @identity_compile_paths LiveShadcnVerification.identity_compile_paths(@repo_root)

  @external_resource @official_examples_path
  @external_resource @snapshot_index_path

  for path <-
        @spec_paths ++
          @snapshot_paths ++
          @parity_example_paths ++
          @ai_source_paths ++
          @verification_rule_paths ++
          @identity_compile_paths do
    @external_resource path
  end

  @verification @verify_path |> File.read!() |> Jason.decode!()

  @evaluation_by_identity (fn ->
                             Map.new(@verification, fn {identity, result} ->
                               [source, name] = String.split(identity, "/", parts: 2)
                               spec = Path.join([@spec_root, source, "#{name}.json"])

                               evaluation =
                                 LiveShadcnVerification.evaluate(
                                   result,
                                   source,
                                   name,
                                   @repo_root,
                                   spec
                                 )

                               {identity, evaluation}
                             end)
                           end).()

  @status_by_identity (fn ->
                         statuses =
                           Map.new(@evaluation_by_identity, fn {identity, evaluation} ->
                             {identity, evaluation.status}
                           end)

                         Map.merge(statuses, LiveShadcnVerification.policy_status_overrides())
                       end).()

  # The sections the AI Elements documentation groups its components under, in
  # the order it lists them. `mix ui.fetch` reads them from upstream's own
  # `meta.json` and the directory each page sits in; this module only reads the
  # manifest, so a component that moves to another section moves here too.
  @sections (fn ->
               manifest = @upstream_path |> File.read!() |> Jason.decode!()

               for section <- get_in(manifest, ["groups", "ai_elements"]) || [],
                   do: {section["title"], section["components"]}
             end).()

  # The markup inside every example function, by function name.
  #
  # Read at compile time, because the file does not change while the server is
  # running and a documentation page should not do file IO to draw itself.
  @sources (fn ->
              {:ok, ast} =
                @examples_path |> File.read!() |> Code.string_to_quoted(token_metadata: true)

              heex = fn
                {:sigil_H, _, [{:<<>>, _, [raw]}, _]} when is_binary(raw) ->
                  raw

                # A body that assigns before it renders. `~H` is the last thing
                # it does, and the only part a reader is being shown.
                {:__block__, _, statements} ->
                  Enum.find_value(statements, fn
                    {:sigil_H, _, [{:<<>>, _, [raw]}, _]} when is_binary(raw) -> raw
                    _statement -> nil
                  end)

                _body ->
                  nil
              end

              local_delegate = fn
                {name, _, [_argument]} when is_atom(name) -> name
                _body -> nil
              end

              {_ast, functions} =
                Macro.prewalk(ast, [], fn
                  {:defp, _, [{name, _, [_arg]}, [do: body]]} = node, acc when is_atom(name) ->
                    {node, [{name, body} | acc]}

                  node, acc ->
                    {node, acc}
                end)

              direct_sources =
                Map.new(functions, fn {name, body} ->
                  source = heex.(body)
                  {name, source && String.trim_trailing(source)}
                end)
                |> Map.reject(fn {_name, source} -> is_nil(source) end)

              # Some examples keep a public name but reuse another local
              # renderer. Resolve only that single direct call: it preserves
              # the source a reader needs without following arbitrary calls.
              delegated_sources =
                Map.new(functions, fn {name, body} ->
                  target = local_delegate.(body)
                  {name, target && Map.get(direct_sources, target)}
                end)
                |> Map.reject(fn {_name, source} -> is_nil(source) end)

              Map.merge(direct_sources, delegated_sources)
            end).()

  @doc """
  The markup an example is written with.

  The example's `:render` is a captured function, so its name is a fact rather
  than something to derive from the component and the example id — which would
  be a naming convention, and a convention is a rule somebody eventually breaks.
  """
  def source(%{render: render}) do
    {:name, name} = Function.info(render, :name)
    Map.get(@sources, name)
  end

  @doc "Every example function whose markup could be read. For the test."
  def sources, do: @sources

  @doc """
  The module a component name is generated into.

  Two registries each have a `message`, so the storybook names them
  `shadcn-message` and `ai_elements-message`. Everything else is looked for in
  the shadcn namespace first, because that is where most of them are.
  """
  def module(component) do
    {namespaces, base} =
      case component do
        "shadcn-" <> rest -> {[LiveShadcn.UI], rest}
        "ai_elements-" <> rest -> {[LiveAiElements.Components], rest}
        name -> {[LiveShadcn.UI, LiveAiElements.Components], name}
      end

    camel = base |> String.replace("-", "_") |> Macro.camelize()

    Enum.find_value(namespaces, fn namespace ->
      module = Module.concat(namespace, camel)
      if Code.ensure_loaded?(module), do: module
    end)
  end

  @doc """
  Every function a component exports, with its attributes and slots.

  Sorted by name, so the page reads the same way twice. `:rest` is dropped from
  the attribute table and reported separately: a `:global` is not an attribute a
  caller passes but a statement that every other attribute is passed through,
  and listing it beside `variant` says the wrong thing.
  """
  def api(component) do
    case module(component) do
      nil ->
        []

      module ->
        module.__components__()
        |> Enum.sort_by(fn {name, _meta} -> name end)
        |> Enum.map(fn {name, meta} ->
          %{
            name: name,
            attrs: meta.attrs |> Enum.reject(&(&1.type == :global)) |> Enum.sort_by(& &1.name),
            globals: Enum.filter(meta.attrs, &(&1.type == :global)),
            slots: Enum.sort_by(meta.slots, & &1.name)
          }
        end)
    end
  end

  @doc "What `mix ui.add` is called with, which is the component's own name."
  def install(component) do
    case component do
      "shadcn-" <> rest -> "mix ui.add #{rest}"
      "ai_elements-" <> _rest -> "The AI Elements package is a dependency, not a copy."
      name -> "mix ui.add #{name}"
    end
  end

  # The three published packages, and the namespace each one generates into.
  #
  # `live_base` has no namespace here because it draws nothing: it is the
  # behaviour the other two share — the hooks, the ARIA, the measurement — and a
  # component list is the wrong shape for it. It is still one of the three, and
  # a reader who does not know that will not understand why installing
  # `live_shadcn` pulls something else in.
  @packages [
    {:live_shadcn, LiveShadcn.UI},
    {:live_ai_elements, LiveAiElements.Components},
    {:live_base, nil}
  ]

  @doc """
  The three libraries, each with what it says about itself and what it draws.

  A reader meeting `Chain Of Thought` next to `Checkbox` in one alphabetical
  list has no way to tell that installing the second is `mix ui.add checkbox`
  and the first is a dependency — or that the two entries both called `Message`
  are different components from different registries.

  Which package a component ships in is read rather than maintained: the module
  a component generates into says which namespace it is in, and the namespace
  belongs to exactly one package. It is what `groups/0` names each of its groups
  by, so the sidebar answers "how do I install this" as well as "where is it".

  The blurb and the version are the package's own, out of its application spec,
  which is what `mix.exs` puts there. Typing them here would be a second copy
  of something hex already publishes.
  """
  def libraries do
    for {app, namespace} <- @packages do
      %{
        package: to_string(app),
        blurb: spec(app, :description),
        version: spec(app, :vsn),
        components: components_in(namespace)
      }
    end
  end

  @doc """
  The components, grouped for the navigation.

  The sections are the groups, and the package is named once, on the first group
  that ships in it — which is how it is installed, and what tells the two
  components called `Message` apart.

  Neither is typed here: the package comes from the namespace the component
  generates into, and the sections come from `registry/UPSTREAM.json`.

  `live_shadcn` has one group and no sections, because ui.shadcn.com does not
  group its components either. It is titled after the package.
  """
  def groups do
    shadcn = shadcn_components()
    documented = MapSet.new(Examples.components())

    sections =
      for {title, names} <- @sections,
          components = Enum.flat_map(names, &id(&1, documented)),
          components != [],
          do: %{title: title, components: components}

    named([%{title: "live_shadcn", components: shadcn} | sections])
  end

  # The storybook id a documented component has here, if it has one at all. A
  # page can name a component this pipeline does not generate, and both
  # registries have a `message` — which is why one of them is `ai_elements-`.
  defp id(name, documented) do
    ["ai_elements-" <> name, name]
    |> Enum.filter(fn candidate ->
      MapSet.member?(documented, candidate) and
        String.starts_with?(to_string(module(candidate)), "Elixir.LiveAiElements")
    end)
    |> Enum.take(1)
  end

  # The package a group ships in, said on the first group that ships in it.
  defp named(groups) do
    {named, _seen} =
      Enum.map_reduce(groups, MapSet.new(), fn group, seen ->
        package = library(hd(group.components)).package
        said? = MapSet.member?(seen, package) or group.title == package
        {Map.put(group, :package, unless(said?, do: package)), MapSet.put(seen, package)}
      end)

    named
  end

  @doc """
  The library a component ships in, and where its spec lives.

  The page used to say `registry/spec/<component>.json`, which is not a path
  that exists: the registry is one directory per source, because a name is not
  an identity — each registry has a `message`. So it named a file nobody could
  open, for a library it did not say.
  """
  def library(component) do
    {source, name} = identity(component)
    component_module = module(component)
    namespace = to_string(component_module)

    package =
      if is_nil(component_module) and source == "shadcn" do
        "live_shadcn"
      else
        Enum.find_value(@packages, fn
          {app, ns} when not is_nil(ns) ->
            String.starts_with?(namespace, to_string(ns)) && to_string(app)

          _base ->
            nil
        end)
      end

    %{package: package, spec: "registry/spec/#{source}/#{name}.json"}
  end

  @doc "The highest pipeline stage that has current evidence for a documented component."
  @spec status(String.t()) ::
          :verified | :failed | :stale | :not_verified | :local_only | :no_dom
  def status(component) do
    {source, name} = identity(component)
    Map.get(@status_by_identity, "#{source}/#{name}", :not_verified)
  end

  @doc "Human-readable verification label for a documented component."
  def status_label(component), do: evaluation(component).label

  @doc "Verification evaluation with per-check reasons for a documented component."
  def evaluation(component) do
    {source, name} = identity(component)
    Map.get(@evaluation_by_identity, "#{source}/#{name}", default_evaluation())
  end

  defp default_evaluation do
    %{
      status: :not_verified,
      label: LiveShadcnVerification.status_label(:not_verified),
      reason: "No verification record exists",
      checks: []
    }
  end

  def status_classes(status) do
    Map.fetch!(
      %{
        verified: "bg-green-100 text-green-800 dark:bg-green-950 dark:text-green-300",
        failed: "bg-red-100 text-red-900 dark:bg-red-950 dark:text-red-300",
        stale: "bg-orange-100 text-orange-900 dark:bg-orange-950 dark:text-orange-300",
        not_verified: "bg-amber-100 text-amber-900 dark:bg-amber-950 dark:text-amber-300",
        local_only: "bg-slate-100 text-slate-800 dark:bg-slate-950 dark:text-slate-300",
        no_dom: "bg-violet-100 text-violet-800 dark:bg-violet-950 dark:text-violet-300"
      },
      status
    )
  end

  def check_outcome_label(:passed), do: "Passed"
  def check_outcome_label(:failed), do: "Failed"
  def check_outcome_label(:stale), do: "Stale"
  def check_outcome_label(:skipped), do: "Skipped"
  def check_outcome_label(:incomplete), do: "Incomplete"
  def check_outcome_label(:not_run), do: "Not run"
  def check_outcome_label(outcome), do: outcome |> to_string() |> String.capitalize()

  defp identity(component) do
    namespace = to_string(module(component))

    source =
      if String.starts_with?(namespace, "Elixir.LiveAiElements"),
        do: "ai_elements",
        else: "shadcn"

    name = String.replace(component, ["shadcn-", "ai_elements-"], "")
    {source, name}
  end

  defp components_in(nil), do: []

  defp components_in(namespace) do
    prefix = to_string(namespace)

    Examples.components()
    |> Enum.filter(&String.starts_with?(to_string(module(&1)), prefix))
    |> Enum.sort()
  end

  # Some official shadcn pages are examples made from several generated
  # primitives. They have documentation and preview routes, but no one module
  # named after the page. Keep them in the shadcn navigation with the primitive
  # pages they use.
  defp shadcn_components do
    composites =
      Examples.components()
      |> Enum.filter(&is_nil(module(&1)))

    (components_in(LiveShadcn.UI) ++ composites)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp spec(app, key) do
    Application.load(app)

    case Application.spec(app, key) do
      nil -> nil
      value -> to_string(value)
    end
  end

  @doc "The title a component is shown under."
  def title(component) do
    component
    |> String.replace(["shadcn-", "ai_elements-"], "")
    |> String.split("-")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
