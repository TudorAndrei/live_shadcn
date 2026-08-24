defmodule LiveShadcnTools.Gen.Toast do
  @moduledoc """
  The `toast` recipe: a stack of messages the reader did not ask for.

  ## Why the list is a slot

  React's toast is a manager object the client holds — `toast.add(…)` from
  anywhere, and the component reads it. A LiveView already has somewhere to
  keep a list, and a list the client held would disagree with the server's the
  moment it re-rendered: the reader would watch a dismissed message come back.

  So the toasts are a slot with entries, the way a tab set's tabs are:

      <.toaster id="toasts" dismiss="dismiss_toast">
        <:toast :for={t <- @toasts} id={t.id} type={t.type} title={t.title}>
          {t.description}
        </:toast>
      </.toaster>

  Nine exported parts become one function, because nine parts of one stack have
  to agree about where each toast sits and how tall it is, and that agreement is
  a measurement rather than an id.

  ## What is left to the hook

  Every one of them. See `LiveBase.Toast`.
  """

  alias LiveShadcnTools.Gen.Heex
  alias LiveShadcnTools.Spec

  @required %{
    viewport: "Viewport",
    portal: "Portal",
    root: "Root",
    content: "Content",
    title: "Title",
    description: "Description",
    close: "Close"
  }

  @doc "The attribute names the client hook owns rather than the server."
  def client_attributes do
    ~w(data-expanded data-swiping data-swipe-direction data-behind data-limited
       data-starting-style data-ending-style)
  end

  @doc "The module source for one component."
  def module(spec, opts) do
    if spec["name"] == "sonner" do
      sonner_module(spec, opts)
    else
      roles = roles!(spec)

      """
      defmodule #{inspect(Keyword.fetch!(opts, :module))} do
      #{moduledoc(spec)}

        use Phoenix.Component

        alias LiveBase.Toast
        alias Phoenix.LiveView.JS

      #{function_doc()}
      #{declarations()}
        def toaster(assigns) do
          ~H\"\"\"
      #{markup(spec, roles)}
          \"\"\"
        end
      end
      """
    end
  end

  # Sonner exposes only a manager. LiveView keeps the corresponding list on
  # the server, then gives the existing toast hook the geometry it cannot know.
  defp sonner_module(spec, opts) do
    toaster_class = toaster_class(spec)
    toaster_style = toaster_style(spec)
    toast_class = toast_class(spec)

    """
    defmodule #{inspect(Keyword.fetch!(opts, :module))} do
    #{moduledoc(spec)}

      use Phoenix.Component

      alias LiveBase.Toast
      alias Phoenix.LiveView.JS

    #{function_doc()}
    #{declarations()}
      def toaster(assigns) do
        ~H\"\"\"
        <section
          id={@id}
          data-lb-toasts
          data-lb-dismiss={@dismiss}
          data-lb-duration={@duration}
          data-lb-limit={@limit}
          phx-hook={Toast.hook()}
          role="region"
          aria-label={@label}
          class={[#{inspect(toaster_class)}, @class]}
          style=#{inspect(toaster_style)}
          {@rest}
        >
          <article
            :for={toast <- Enum.reverse(@toast)}
            id={Toast.toast_id(@id, toast[:id])}
            data-slot="toast"
            data-type={toast[:type]}
            role="status"
            aria-live="polite"
            class=#{inspect(toast_class)}
          >
            <span data-slot="toast-icon"><LiveShadcn.Icon.icon name={icon(toast[:type])} /></span>
            <div class="flex min-w-0 flex-1 flex-col gap-1">
              <p :if={toast[:title]}>{toast[:title]}</p>
              {render_slot(toast)}
            </div>
            <button
              type="button"
              aria-label="Close toast"
              phx-click={JS.push(@dismiss, value: %{id: Toast.toast_id(@id, toast[:id])})}
            >
              <LiveShadcn.Icon.icon name="x" />
            </button>
          </article>
        </section>
        \"\"\"
      end

      defp icon("success"), do: "circle-check"
      defp icon("warning"), do: "triangle-alert"
      defp icon("error"), do: "octagon-x"
      defp icon("loading"), do: "loader-2"
      defp icon(_type), do: "info"
    end
    """
  end

  defp toast_class(spec) do
    spec["parts"]
    |> Enum.find(&(&1["name"] == "toaster"))
    |> get_in(["tree", "attrs"])
    |> Enum.find(&(&1["name"] == "toastOptions"))
    |> get_in(["value", "classNames", "toast"])
    |> case do
      class when is_binary(class) -> class
      _other -> raise "Sonner's toaster has no toastOptions.classNames.toast"
    end
  end

  defp toaster_class(spec), do: sonner_tree(spec) |> Map.fetch!("class")

  defp toaster_style(spec) do
    spec
    |> sonner_tree()
    |> Map.fetch!("attrs")
    |> Enum.find(&(&1["name"] == "style"))
    |> Map.fetch!("value")
    |> Enum.map_join("; ", fn
      %{"property" => property, "kind" => "text", "value" => value} -> "#{property}: #{value}"
      entry -> raise "Sonner's style has an unsupported declaration: #{inspect(entry)}"
    end)
  end

  defp sonner_tree(spec) do
    spec["parts"]
    |> Enum.find(&(&1["name"] == "toaster"))
    |> Map.fetch!("tree")
  end

  defp roles!(spec) do
    Map.new(@required, fn {role, primitive} ->
      case find(spec["parts"], primitive) do
        nil -> raise "#{spec["name"]} has no #{primitive} part, so it is not a toast"
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

  # The viewport holds one toast per entry, and each toast holds its own
  # content. shadcn assembles none of this — its `Toaster` maps over a manager
  # — so the recipe nests them, the way the dialog recipe assembles a dialog.
  defp markup(spec, roles) do
    toaster = Enum.find(spec["parts"], &(&1["name"] == "toaster"))
    icon = helper!(toaster["tree"], &(&1["slot"] == "toast-icon"))

    text =
      helper!(toaster["tree"], &(&1["class"] == "flex min-w-0 flex-1 flex-col gap-1"))

    body =
      [
        icon_markup(icon),
        text_markup(
          text,
          render(spec, roles, roles.title, "{toast[:title]}") <>
            "\n" <> render(spec, roles, roles.description, "{render_slot(toast)}")
        ),
        close_markup(spec, roles)
      ]
      |> Enum.join("\n")

    content = render(spec, roles, roles.content, body)
    viewport = render(spec, roles, roles.viewport, render(spec, roles, roles.root, content))
    render(spec, roles, roles.portal, viewport)
  end

  defp helper!(node, predicate) do
    case find_node(node, predicate) do
      nil -> raise "toast list has no required helper"
      found -> found
    end
  end

  defp find_node(node, predicate) do
    if predicate.(node) do
      node
    else
      node
      |> Map.get("children")
      |> List.wrap()
      |> Enum.find_value(&find_node(&1, predicate))
    end
  end

  defp icon_markup(icon) do
    """
    <span data-slot="toast-icon" class=#{inspect(icon["class"])}>
      <LiveShadcn.Icon.icon name="info" />
    </span>
    """
  end

  defp text_markup(text, children) do
    """
    <div class=#{inspect(text["class"])}>
    #{children}
    </div>
    """
  end

  defp close_markup(_spec, roles) do
    class = roles.close.node["class"]

    """
    <LiveShadcn.UI.Button.button
      data-slot="toast-close"
      variant="ghost"
      size="icon-sm"
      aria-label="Close toast"
      phx-click={JS.push(@dismiss, value: %{id: Toast.toast_id(@id, toast[:id])})}
      data-type={toast[:type]}
      class=#{inspect(class)}
    >
      <LiveShadcn.Icon.icon name="x" />
    </LiveShadcn.UI.Button.button>
    """
  end

  # A part whose content the recipe supplies takes a children marker; one whose
  # content it does not takes the default upstream wrote there.
  #
  # The close button is the second kind. `{children ?? <XIcon />}` becomes
  # `<%= if @inner_block == [] do %>` when the marker survives — and this
  # component has no `inner_block`, because the toaster's slot is the toast and
  # not the button inside it. Resolving the marker here is the same answer the
  # fold gives a reference that wrapped nothing.
  defp render(spec, roles, role, :default),
    do: draw(spec, roles, role, defaulted(role.node), "")

  defp render(spec, roles, role, children),
    do: draw(spec, roles, role, Heex.with_children(role.node), children)

  defp defaulted(%{"type" => "children"} = node), do: Map.get(node, "default") || []

  defp defaulted(node) when is_map(node) do
    Map.update(node, "children", [], fn children ->
      children |> List.wrap() |> Enum.flat_map(&List.wrap(defaulted(&1)))
    end)
  end

  defp defaulted(node), do: node

  defp draw(spec, roles, role, node, children) do
    Heex.render(node, %{
      attrs: attributes(roles),
      props: props(spec, roles),
      children: children,
      class: class_for(role, roles),
      params: Map.get(role.part, "params", %{}),
      contexts: Map.get(role.part, "contexts", []),
      variants: spec["variants"] || %{},
      client_attributes: client_attributes(),
      hook_part: Spec.key(roles.viewport.node),
      rest: role == roles.viewport
    })
  end

  # The caller's class reaches the viewport, which is the element they wrote.
  defp class_for(role, roles), do: if(role == roles.viewport, do: "@class", else: nil)

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
    %{
      Spec.key(roles.viewport.node) => [
        {"id", :code, "@id"},
        {"phx-hook", :code, "Toast.hook()"},
        {"data-lb-toasts", :bare},
        {"data-lb-dismiss", :code, "@dismiss"},
        {"data-lb-duration", :code, "@duration"},
        {"data-lb-limit", :code, "@limit"},
        {"role", :text, "region"},
        {"aria-label", :code, "@label"}
      ],
      Spec.key(roles.root.node) => [
        {":for", :code, "toast <- Enum.reverse(@toast)"},
        {"id", :code, "Toast.toast_id(@id, toast[:id])"},
        {"data-type", :code, "toast[:type]"},
        {"role", :text, "status"},
        {"aria-live", :text, "polite"}
      ],
      Spec.key(roles.content.node) => [],
      # An empty heading is a heading a screen reader still announces, so a
      # toast with no title draws none rather than drawing an empty one.
      Spec.key(roles.title.node) => [
        {":if", :code, "toast[:title]"},
        {"data-type", :code, "toast[:type]"}
      ],
      Spec.key(roles.description.node) => [{"data-type", :code, "toast[:type]"}],
      Spec.key(roles.close.node) => [
        {"type", :text, "button"},
        {"phx-click", :code,
         ~s|JS.push(@dismiss, value: %{id: Toast.toast_id(@id, toast[:id])})|},
        {"data-type", :code, "toast[:type]"}
      ]
    }
  end

  defp declarations do
    """
      attr :id, :string, required: true, doc: "The hook needs one, and each toast derives its own."

      attr :dismiss, :string,
        required: true,
        doc: "The event pushed when a toast is closed or times out. Its payload is `%{id: id}`."

      attr :duration, :integer,
        default: 5000,
        doc: "How long a toast stays, in milliseconds. Zero to leave it until it is closed."

      attr :limit, :integer,
        default: 3,
        doc: "How many newest toasts stay visible. Older toasts stay in the server list and are marked limited."

      attr :label, :string, default: "Notifications", doc: "Names the region to a screen reader."
      attr :class, :any, default: nil, doc: "Appended to the class string upstream renders."
      attr :rest, :global

      slot :toast, doc: "One message. The slot's content is its description." do
        attr :id, :string, required: true, doc: "What comes back with the dismiss event."
        attr :title, :string
        attr :type, :string, doc: "`success`, `info`, `warning` or `error`."
      end
    """
  end

  defp function_doc do
    ~S'''
      @doc """
      A stack of messages the reader did not ask for.

          <.toaster id="toasts" dismiss="dismiss_toast">
            <:toast :for={t <- @toasts} id={t.id} type={t.type} title={t.title}>
              {t.description}
            </:toast>
          </.toaster>

      The list is yours. React's toast is a manager the client holds; a
      LiveView already has somewhere to keep a list, and one the client held
      would disagree with the server's the moment it re-rendered — the reader
      would watch a dismissed message come back.

      So closing one is an event, and so is timing out:

          def handle_event("dismiss_toast", %{"id" => id}, socket) do
            {:noreply, update(socket, :toasts, &Enum.reject(&1, fn t -> t.id == id end))}
          end

      How the stack is placed — how tall each toast turned out, how far back it
      sits, how far a finger has pushed it — is measured in the browser, which
      is the only place any of it is known.
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
