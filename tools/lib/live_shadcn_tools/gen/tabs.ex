defmodule LiveShadcnTools.Gen.Tabs do
  @moduledoc """
  The `tabs` recipe: a set of panels of which exactly one is shown.

  ## Why the tabs are data

  A tab and its panel are two elements that have to agree about a third thing —
  which one is showing. shadcn exports four components and lets React context
  carry that agreement; in HEEx it would be a value the caller repeats on both
  sides, and a panel that never shows the first time they mistyped it.

  So the tabs are a slot with a value, and the recipe pairs them:

      <.tabs id="stages" value="spec">
        <:tab value="fetch" label="Fetch">registry/UPSTREAM.json</:tab>
        <:tab value="spec" label="Spec">registry/spec/*.json</:tab>
      </.tabs>

  One list of tabs in, one row of buttons and one panel each out, and the ids
  that tie them together derived from the value the caller already wrote.

  ## Keyboard

  The APG asks for arrow keys along the row and Home and End at its ends. That
  is the one thing here no `JS` command can do, and it is the roving focus the
  architecture already reserved a hook for. The hook works out which tab a key
  means and clicks it; what choosing a tab does stays in the command on the tab.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Spec

  @required %{root: "Root", list: "List", tab: "Tab", panel: "Panel"}

  @doc "The attribute names the client hook owns rather than the server."
  def client_attributes, do: ["data-starting-style", "data-ending-style"]

  @doc """
  The expression that computes an attribute the spec says an element carries.
  """
  def attribute!(name, role)

  def attribute!(name, _role) when name in ["data-starting-style", "data-ending-style"],
    do: :client

  def attribute!("data-orientation", _role), do: {:code, "@orientation"}

  # Base UI writes the orientation twice: once as a value and once as a bare
  # attribute, because a Tailwind variant can only key on presence.
  def attribute!("data-horizontal", _role), do: {:code, ~s|flag(@orientation == "horizontal")|}
  def attribute!("data-vertical", _role), do: {:code, ~s|flag(@orientation == "vertical")|}
  def attribute!("data-active", :tab), do: {:code, "flag(active?(tab, @active))"}
  def attribute!("data-hidden", :panel), do: {:code, "flag(not active?(tab, @active))"}
  def attribute!("data-disabled", _role), do: {:code, "flag(tab[:disabled])"}

  # shadcn styles the disabled tab against the ARIA attribute, which Base UI
  # does not document. Both are contracts; the class string is the one that
  # would break.
  def attribute!("aria-disabled", _role), do: {:code, "flag(tab[:disabled])"}
  def attribute!("data-index", _role), do: {:code, "index"}

  # Which way the reader moved to get here. It is a fact about the last click,
  # which the server did not see.
  def attribute!("data-activation-direction", _role), do: :client

  def attribute!(name, role) do
    raise """
    the tabs recipe does not know how to compute #{name} on the #{role}.

    Base UI documents the attribute, so a shadcn class string may read it. Give
    LiveShadcnTools.Gen.Tabs.attribute!/2 the expression that computes it.
    """
  end

  @doc "The module source for one component."
  def module(spec, opts) do
    roles = roles!(spec)
    name = String.replace(spec["name"], "-", "_")

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

      alias LiveBase.Tabs

    #{function_doc(spec, name)}
    #{declarations(spec, roles)}
      def #{name}(assigns) do
        assigns = assign(assigns, :active, active(assigns))

        ~H\"\"\"
    #{markup(spec, roles)}
        \"\"\"
      end

      # Exactly one tab shows. If the caller named one, it is that one; if they
      # named nothing, it is the first, because a tab set with no panel showing
      # is a tab set that looks broken.
      defp active(%{value: nil, tab: [first | _]}), do: first[:value]
      defp active(%{value: value}), do: value

      defp active?(tab, value), do: tab[:value] == value

      defp flag(true), do: ""
      defp flag(_state), do: nil
    #{Presentational.variant_table(spec)}end
    """
  end

  defp roles!(spec) do
    Map.new(@required, fn {role, primitive} ->
      case find(spec["parts"], primitive) do
        nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a tab set"
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

  defp markup(spec, roles) do
    tab = render(spec, roles, roles.tab, "{tab.label}")
    panel = render(spec, roles, roles.panel, "{render_slot(tab)}")
    list = render(spec, roles, roles.list, tab)

    render(spec, roles, roles.root, list <> "\n" <> panel)
  end

  defp render(spec, roles, role, children) do
    Heex.render(Heex.with_children(role.node), %{
      attrs: attributes(spec, roles),
      children: children,
      class: class_expression(spec, role.part),
      params: Map.get(role.part, "params", %{}),
      variants: Presentational.variant_table_of(role.part, spec),
      client_attributes: client_attributes(),
      hook_part: nil,
      rest: role.node["part"] == "Root"
    })
  end

  defp class_expression(spec, part) do
    case String.replace_prefix(part["name"], String.replace(spec["name"], "-", "_"), "") do
      "" -> "@class"
      "_" <> suffix -> "@#{suffix}_class"
    end
  end

  defp attributes(spec, roles) do
    Map.new(roles, fn {role, %{node: node}} ->
      {Spec.key(node), role_attributes(role) ++ documented(spec, node, role)}
    end)
  end

  defp documented(spec, node, role) do
    documented = get_in(spec, ["primitives", Spec.key(node), "data"]) || []
    read = get_in(node, ["reads", "self"]) || []

    (documented ++ read)
    |> Enum.uniq()
    |> Enum.flat_map(fn name ->
      case attribute!(name, role) do
        :client -> []
        {:code, expression} -> [{name, :code, expression}]
      end
    end)
  end

  defp role_attributes(:root), do: [{"id", :code, "@id"}]

  # The list is where the arrow keys are handled, because the list is what
  # knows the order of the tabs.
  defp role_attributes(:list) do
    [
      {"id", :code, ~s|@id <> "-list"|},
      {"role", :text, "tablist"},
      {"aria-orientation", :code, "@orientation"},
      {"phx-hook", :code, "Tabs.hook()"},
      {"data-lb-roving", :text, "tab"},
      {"data-lb-orientation", :code, "@orientation"},
      {"data-lb-loop", :bare},
      {"data-lb-activate", :bare}
    ]
  end

  defp role_attributes(:tab) do
    [
      {":for", :code, "{tab, index} <- Enum.with_index(@tab)"},
      {"id", :code, "Tabs.tab_id(@id, tab[:value])"},
      {"type", :text, "button"},
      {"role", :text, "tab"},
      {"aria-selected", :code, "to_string(active?(tab, @active))"},
      {"aria-controls", :code, "Tabs.panel_id(@id, tab[:value])"},
      {"tabindex", :code, ~s|if(active?(tab, @active), do: "0", else: "-1")|},
      {"phx-click", :code, "Tabs.activate(tabs: @id, value: tab[:value])"},
      {"phx-mounted", :code, "Tabs.owned_attributes(:tab)"}
    ]
  end

  defp role_attributes(:panel) do
    [
      {":for", :code, "{tab, index} <- Enum.with_index(@tab)"},
      {"id", :code, "Tabs.panel_id(@id, tab[:value])"},
      {"role", :text, "tabpanel"},
      {"aria-labelledby", :code, "Tabs.tab_id(@id, tab[:value])"},
      {"tabindex", :text, "0"},
      {"hidden", :code, "not active?(tab, @active)"},
      {"phx-mounted", :code, "Tabs.owned_attributes(:panel)"}
    ]
  end

  # ---- declarations ----

  defp declarations(spec, roles) do
    """
      attr :id, :string, required: true, doc: "Every id inside the tab set derives from it."
      attr :value, :string, default: nil, doc: "Which tab shows. Defaults to the first."
      attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
    #{part_classes(spec, roles)}#{own_params(spec, roles)}  attr :rest, :global

      slot :tab, required: true, doc: "One tab and the panel it shows." do
        attr :value, :string, required: true, doc: "Unique. Both ids derive from it."
        attr :label, :any, required: true, doc: "What the tab reads."
        attr :disabled, :boolean, doc: "Whether the tab refuses interaction."
      end
    """
  end

  defp part_classes(spec, roles) do
    roles
    |> ordered()
    |> Enum.reject(fn {role, _} -> role == :root end)
    |> Enum.map(fn {_role, %{part: part}} -> class_suffix(spec, part) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.map_join(&~s|  attr :#{&1}_class, :any, default: nil\n|)
  end

  defp class_suffix(spec, part) do
    case String.replace_prefix(part["name"], String.replace(spec["name"], "-", "_"), "") do
      "_" <> suffix -> suffix
      _ -> nil
    end
  end

  @declared ~w(class_name children render id value orientation)

  defp own_params(spec, roles) do
    roles
    |> ordered()
    |> Enum.flat_map(fn {_role, %{part: part}} -> Presentational.attributes(part, spec) end)
    |> Enum.uniq_by(& &1.name)
    |> Enum.reject(&(&1.name in @declared))
    |> Enum.sort_by(& &1.name)
    |> Enum.map_join(fn attribute -> "#{Presentational.declaration(attribute)}\n" end)
  end

  # Atoms sort by when the VM first saw them, not by their letters, so the
  # order is made explicit rather than inherited from the map.
  defp ordered(roles), do: Enum.sort_by(roles, fn {role, _} -> Atom.to_string(role) end)

  # ---- documentation ----

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

  defp function_doc(spec, name) do
    """
      @doc \"\"\"
      #{Heex.summary(spec)}

          <.#{name} id="stages" value="spec">
            <:tab value="fetch" label="Fetch">registry/UPSTREAM.json</:tab>
            <:tab value="spec" label="Spec">registry/spec/*.json</:tab>
          </.#{name}>

      Choosing a tab runs entirely on the client. Exactly one panel shows, and
      the tab that shows it is the one the arrow keys land on.
      \"\"\"\
    """
  end
end
