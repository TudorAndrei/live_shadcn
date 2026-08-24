defmodule LiveShadcnTools.Gen.Dialog do
  @moduledoc """
  The `dialog` recipe: something that opens over the page and takes the focus
  with it. Dialog, alert dialog, sheet, drawer.

  ## Why one function

  shadcn exports nine components for a dialog, and every one of them has to
  agree about which dialog it belongs to. In React that agreement is context; in
  HEEx it would be an id the caller repeats nine times, and a dialog whose
  `aria-labelledby` points at nothing the first time they mistyped it.

  So the recipe folds them, the same way the disclosure recipe does:

      <.dialog id="confirm">
        <:trigger>Delete</:trigger>
        <:title>Are you sure?</:title>
        <:description>This cannot be undone.</:description>
        Deleting removes the component and its spec.
        <:footer>…</:footer>
      </.dialog>

  Every id the ARIA contract needs is derived from `confirm`.

  ## What is a slot and what is not

  A part becomes a slot when the caller supplies its content: the trigger, the
  title, the description, the footer. A part that only wraps — the portal, the
  backdrop, the header — is markup the recipe assembles.

  The close button is neither. shadcn renders it inside the popup already,
  behind `showCloseButton`, so the recipe reads that from the spec rather than
  inventing an attribute for it.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Gen.Presentational
  alias LiveShadcnTools.Spec

  @client_attributes ["data-starting-style", "data-ending-style"]

  # Which Base UI part plays which role. `Popup` is the dialog itself; Base UI
  # calls the layer behind it a `Backdrop` and shadcn calls it an overlay.
  @required %{root: "Root", trigger: "Trigger", popup: "Popup"}
  @optional %{
    backdrop: "Backdrop",
    portal: "Portal",
    title: "Title",
    description: "Description",
    close: "Close"
  }

  @doc "The attribute names the client hook owns rather than the server."
  def client_attributes, do: @client_attributes

  @doc """
  The expression that computes an attribute the spec says an element carries.

  A dialog's open state lives entirely in the browser, so almost every one of
  these is a constant: the server renders the closed state and the `JS` command
  changes it.
  """
  def attribute!(name, role)

  def attribute!(name, _role) when name in @client_attributes, do: :client
  def attribute!("data-open", _role), do: {:code, "flag(@open)"}
  def attribute!("data-closed", _role), do: {:code, "flag(not @open)"}
  def attribute!("data-popup-open", _role), do: {:code, "flag(@open)"}
  def attribute!("data-disabled", _role), do: {:code, "flag(@disabled)"}

  # Nesting is a fact about the DOM the server does not have. Base UI sets both
  # from the client, and so does the hook.
  def attribute!("data-nested", _role), do: :client
  def attribute!("data-nested-dialog-open", _role), do: :client

  def attribute!(name, role) do
    raise """
    the dialog recipe does not know how to compute #{name} on the #{role}.

    Base UI documents the attribute, so a shadcn class string may read it. Give
    LiveShadcnTools.Gen.Dialog.attribute!/2 the expression that computes it.
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

      alias LiveBase.Dialog

    #{function_doc(spec, name)}
    #{declarations(spec, roles)}
      def #{name}(assigns) do
        ~H\"\"\"
    #{markup(spec, roles)}
        \"\"\"
      end

      defp flag(true), do: ""
      defp flag(_state), do: nil
    #{Presentational.variant_table(spec)}end
    """
  end

  defp roles!(spec) do
    required =
      Map.new(@required, fn {role, primitive} ->
        case find(spec["parts"], primitive) do
          nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a dialog"
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

  # A part that renders no element is still a part. Base UI's dialog `Root` is
  # one, and it is what the recipe hangs every derived id off.
  defp locate(%{"part" => primitive} = node, primitive), do: node

  defp locate(node, primitive),
    do: node |> Map.get("children") |> List.wrap() |> Enum.find_value(&locate(&1, primitive))

  # ---- markup ----

  # The dialog is assembled rather than nested from one tree, because shadcn's
  # own `DialogContent` already assembles it: portal, then overlay, then popup.
  defp markup(spec, roles) do
    """
    <div id={@id} data-slot="#{slot(roles.root)}" {@rest}>
    #{render(spec, roles, roles.trigger, "{render_slot(@trigger)}")}
    #{content(spec, roles)}
    </div>\
    """
  end

  defp content(spec, roles) do
    body =
      [
        heading(spec, roles),
        "  {render_slot(@inner_block)}",
        "  <div :if={@footer != []} data-slot=\"#{footer_slot(spec)}\" class=\"#{footer_class(spec)}\">",
        "    {render_slot(@footer)}",
        "  </div>"
      ]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.join("\n")

    backdrop = if roles[:backdrop], do: render(spec, roles, roles.backdrop, nil), else: ""

    backdrop <> "\n" <> render(spec, roles, roles.popup, body)
  end

  defp heading(spec, roles) do
    title = if roles[:title], do: render(spec, roles, roles.title, "{render_slot(@title)}")

    description =
      if roles[:description],
        do: render(spec, roles, roles.description, "{render_slot(@description)}")

    case Enum.reject([title, description], &is_nil/1) do
      [] -> nil
      parts -> header(spec, Enum.join(parts, "\n"))
    end
  end

  # shadcn's header is a plain `<div>` with a class string, so it is markup the
  # recipe places rather than a part with behaviour.
  defp header(spec, inside) do
    case plain(spec, "header") do
      nil -> inside
      part -> ~s|  <div data-slot="#{slot(part)}" class="#{class(part)}">\n#{inside}\n  </div>|
    end
  end

  defp footer_slot(spec), do: spec |> plain("footer") |> slot()
  defp footer_class(spec), do: spec |> plain("footer") |> class()

  defp plain(spec, suffix) do
    name = String.replace(spec["name"], "-", "_") <> "_" <> suffix

    case Enum.find(spec["parts"], &(&1["name"] == name)) do
      nil -> nil
      part -> %{node: part["tree"], part: part}
    end
  end

  defp slot(nil), do: nil
  defp slot(%{node: node}), do: node["slot"]

  defp class(nil), do: ""
  defp class(%{node: node}), do: node["class"]

  defp render(spec, roles, role, children) do
    Heex.render(inject(role.part["tree"], role.node, children), %{
      attrs: attributes(spec, roles),
      children: children || "",
      class: class_expression(spec, role.part),
      params: Map.get(role.part, "params", %{}),
      contexts: Map.get(role.part, "contexts", []),
      variants: spec["variants"] || %{},
      client_attributes: @client_attributes,
      hook_part: Spec.key(roles.popup.node),
      rest: false
    })
  end

  # A part's own tree may hold more than the part — shadcn's `DialogContent`
  # wraps the popup in a portal — so the tree is rendered from the role's own
  # node down, not from the exported function's root.
  defp inject(_tree, node, nil), do: node

  defp inject(_tree, node, _children), do: Heex.with_children(node)

  defp class_expression(spec, part) do
    case String.replace_prefix(part["name"], String.replace(spec["name"], "-", "_"), "") do
      "" -> "@class"
      "_content" -> "@class"
      "_" <> suffix -> "@#{suffix}_class"
    end
  end

  defp attributes(spec, roles) do
    Map.new(roles, fn {role, %{node: node}} ->
      {Spec.key(node), role_attributes(role, spec, roles) ++ documented(spec, node, role)}
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

  defp role_attributes(:root, _spec, _roles), do: []

  defp role_attributes(:trigger, _spec, _roles) do
    [
      {"id", :code, "Dialog.trigger_id(@id)"},
      {"type", :text, "button"},
      {"aria-haspopup", :text, "dialog"},
      {"aria-expanded", :code, "to_string(@open)"},
      {"aria-controls", :code, "Dialog.popup_id(@id)"},
      {"phx-click", :code, "Dialog.open(@id)"},
      {"phx-mounted", :code, "Dialog.owned_attributes(:trigger)"}
    ]
  end

  defp role_attributes(:backdrop, _spec, _roles) do
    [
      {"id", :code, "Dialog.backdrop_id(@id)"},
      {"hidden", :code, "not @open"},
      {"phx-click", :code, "if(@dismissable, do: Dialog.close(@id))"},
      {"phx-mounted", :code, "Dialog.owned_attributes(:backdrop)"}
    ]
  end

  defp role_attributes(:popup, _spec, _roles) do
    [
      {"id", :code, "Dialog.popup_id(@id)"},
      {"role", :code, ~s|if(@alert, do: "alertdialog", else: "dialog")|},
      {"aria-modal", :text, "true"},
      {"aria-labelledby", :code, "Dialog.title_id(@id)"},
      {"aria-describedby", :code, "Dialog.description_id(@id)"},
      {"tabindex", :text, "-1"},
      {"hidden", :code, "not @open"},
      {"phx-window-keydown", :code, "if(@dismissable, do: Dialog.close(@id))"},
      {"phx-key", :text, "Escape"},
      {"phx-hook", :code, "Dialog.hook()"},
      {"data-lb-backdrop", :code, "Dialog.backdrop_id(@id)"},
      {"data-lb-modal", :bare},
      {"phx-mounted", :code, "Dialog.owned_attributes(:popup)"}
    ]
  end

  defp role_attributes(:title, _spec, _roles), do: [{"id", :code, "Dialog.title_id(@id)"}]

  defp role_attributes(:description, _spec, _roles),
    do: [{"id", :code, "Dialog.description_id(@id)"}]

  defp role_attributes(:close, _spec, _roles) do
    [
      {"type", :text, "button"},
      {"phx-click", :code, "Dialog.close(@id)"}
    ]
  end

  defp role_attributes(:portal, _spec, _roles), do: []

  # ---- declarations ----

  defp declarations(spec, roles) do
    """
      attr :id, :string, required: true, doc: "Every id inside the dialog derives from it."
      attr :open, :boolean, default: false, doc: "Whether it starts open."
      attr :alert, :boolean, default: false, doc: "An alert dialog interrupts; a dialog does not."
      attr :dismissable, :boolean, default: true, doc: "Whether Escape and the backdrop close it."
      attr :disabled, :boolean, default: false, doc: "Whether the trigger refuses interaction."
      attr :show_close_button, :boolean, default: true, doc: "Whether the popup draws its own close button."
      attr :class, :any, default: nil, doc: "Appended to the dialog's own class string."
    #{part_classes(spec, roles)}#{own_params(spec, roles)}  attr :rest, :global

      slot :trigger, required: true, doc: "What opens it."
    #{part_slots(roles)}  slot :footer, doc: "Actions, along the bottom."
      slot :inner_block, required: true, doc: "The dialog's body."
    """
  end

  # What the parts destructured for themselves, beyond what the recipe already
  # declares. `data-size` on an alert dialog's popup is upstream's prop, and a
  # component that read it without declaring it would raise on first render.
  @declared ~w(class_name children render id open alert dismissable disabled show_close_button)

  defp own_params(spec, roles) do
    roles
    |> ordered()
    |> Enum.flat_map(fn {_role, %{part: part}} -> Presentational.attributes(part, spec) end)
    |> Enum.uniq_by(& &1.name)
    |> Enum.reject(&(&1.name in @declared))
    |> Enum.sort_by(& &1.name)
    |> Enum.map_join(fn attribute -> "#{Presentational.declaration(attribute)}\n" end)
  end

  defp part_classes(spec, roles) do
    roles
    |> ordered()
    |> Enum.reject(fn {role, _} -> role in [:root, :popup] end)
    |> Enum.map(fn {_role, %{part: part}} -> class_suffix(spec, part) end)
    |> Enum.reject(&is_nil/1)
    # Two roles can live in one exported part, and one attribute cannot be
    # declared twice.
    |> Enum.uniq()
    |> Enum.map_join(&~s|  attr :#{&1}_class, :any, default: nil\n|)
  end

  # Atoms sort by when the VM first saw them, not by their letters, so
  # iterating a map keyed by atom gives a different order in a different run.
  # Generated output has to be byte-identical every time, so the order is made
  # explicit rather than inherited from the map.
  defp ordered(roles), do: Enum.sort_by(roles, fn {role, _} -> Atom.to_string(role) end)

  defp class_suffix(spec, part) do
    case String.replace_prefix(part["name"], String.replace(spec["name"], "-", "_"), "") do
      "_" <> suffix when suffix != "content" -> suffix
      _ -> nil
    end
  end

  defp part_slots(roles) do
    for role <- [:title, :description], roles[role], into: "" do
      ~s|  slot :#{role}, doc: "#{slot_doc(role)}"\n|
    end
  end

  defp slot_doc(:title), do: "What names it. Required for a dialog to be announced."
  defp slot_doc(:description), do: "What describes it, beyond the title."

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

          <.#{name} id="confirm">
            <:trigger>Delete</:trigger>
            <:title>Are you sure?</:title>
            <:description>This cannot be undone.</:description>
            Deleting removes the component and its spec.
          </.#{name}>

      Opening and closing runs entirely on the client. The focus moves in when it
      opens and returns to the trigger when it closes, because a keyboard reader
      who loses their place on the page has lost the page.
      \"\"\"\
    """
  end
end
