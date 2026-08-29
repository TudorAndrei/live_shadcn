defmodule StorybookWeb.DocsLive do
  @moduledoc """
  One component, documented.

  The page has the shape ui.shadcn.com uses — the component, the markup that
  drew it, how to install it, and what it takes — and every one of those four
  comes from somewhere rather than being typed. `StorybookWeb.Docs` says where.

  The examples are rendered inline rather than in a frame. They are the same
  functions `/preview/:component/:example` renders, so a difference between the
  two pages would be a difference in the chrome, and there is a link to the bare
  page for anyone who wants to check.
  """

  use StorybookWeb, :docs_live_view

  import LiveShadcn.UI.Badge
  import LiveShadcn.UI.Table
  import LiveShadcn.UI.Tabs

  alias StorybookWeb.Docs
  alias StorybookWeb.Examples

  defmodule NotFound do
    @moduledoc "A component nobody documented. A 404, not a blank page."
    defexception [:message, plug_status: 404]
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <header>
      <div class="flex flex-wrap items-center gap-2">
        <h1 class="text-3xl font-semibold tracking-tight">{Docs.title(@component)}</h1>
        <.badge
          data-component-status={@status}
          variant={if(@status == :verified, do: "default", else: "secondary")}
          class={[
            "capitalize",
            @status == :verified &&
              "bg-green-100 text-green-800 dark:bg-green-950 dark:text-green-300",
            @status == :unverified &&
              "bg-amber-100 text-amber-900 dark:bg-amber-950 dark:text-amber-300",
            @status == :failed && "bg-red-100 text-red-900 dark:bg-red-950 dark:text-red-300"
          ]}
        >
          {@status}
        </.badge>
        <%!-- Which of the three libraries this one is. Two components are called
              `Message` and they are not the same component; without this the
              page gives a reader no way to tell which one they are reading. --%>
        <.badge variant="secondary"><code>{@library.package}</code></.badge>
        <%!-- Where the page comes from. The spec is the whole answer, so it is
              a badge beside the package rather than a sentence about it. --%>
        <.badge variant="outline"><code>{@library.spec}</code></.badge>
      </div>
    </header>

    <section :for={example <- @examples} class="mt-10">
      <h2 class="text-lg font-medium">{example.title}</h2>
      <p :if={example.description} class="mt-1 text-sm text-muted-foreground">
        {example.description}
      </p>

      <.tabs id={"example-#{example.id}"} value="preview" class="mt-4">
        <:tab value="preview" label="Preview">
          <div class="flex min-h-40 items-center justify-center rounded-md border p-8">
            {example.render.(assigns)}
          </div>
        </:tab>
        <:tab value="code" label="Code">
          <pre class="overflow-x-auto rounded-md border bg-muted p-4 text-xs"><code>{example.source}</code></pre>
        </:tab>
      </.tabs>
    </section>

    <section class="mt-14">
      <h2 class="text-lg font-medium">Installation</h2>
      <pre class="mt-3 overflow-x-auto rounded-md border bg-muted p-4 text-xs"><code>{@install}</code></pre>
    </section>

    <section :for={function <- @api} class="mt-14">
      <h2 class="text-lg font-medium">
        <code>{function.name}/1</code>
      </h2>

      <.table :if={function.attrs != []} class="mt-3">
        <.table_header>
          <.table_row>
            <.table_head>Attribute</.table_head>
            <.table_head>Type</.table_head>
            <.table_head>Default</.table_head>
            <.table_head>Notes</.table_head>
          </.table_row>
        </.table_header>
        <.table_body>
          <.table_row :for={attr <- function.attrs}>
            <.table_cell>
              <code class="text-xs">{attr.name}</code>
              <span :if={attr.required} class="text-xs text-muted-foreground">required</span>
            </.table_cell>
            <.table_cell><code class="text-xs">{inspect(attr.type)}</code></.table_cell>
            <.table_cell><code class="text-xs">{default(attr)}</code></.table_cell>
            <.table_cell class="text-xs text-muted-foreground">
              {attr.doc}
              <span :if={values(attr)} class="block">One of {values(attr)}.</span>
            </.table_cell>
          </.table_row>
        </.table_body>
      </.table>

      <p :if={function.globals != []} class="mt-2 text-xs text-muted-foreground">
        Every other attribute is passed through to the element.
      </p>

      <div :if={function.slots != []} class="mt-4">
        <h3 class="text-sm font-medium">Slots</h3>
        <ul class="mt-2 space-y-1 text-xs text-muted-foreground">
          <li :for={slot <- function.slots}>
            <code>{slot.name}</code>
            <span :if={slot.doc}>— {slot.doc}</span>
            <span :if={slot_attrs(slot) != []}>
              Takes {Enum.map_join(slot_attrs(slot), ", ", &"`#{&1.name}`")}.
            </span>
          </li>
        </ul>
      </div>
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"component" => component}, _session, socket) do
    if component not in Examples.components() do
      raise NotFound, message: "no component called #{component}"
    end

    examples =
      component
      |> Examples.all()
      |> Enum.map(&Map.put(&1, :source, Docs.source(&1)))

    {:ok,
     socket
     |> assign(
       component: component,
       examples: examples,
       api: Docs.api(component),
       library: Docs.library(component),
       status: Docs.status(component),
       install: Docs.install(component),
       page_title: Docs.title(component)
     )
     |> assign(Examples.page_assigns())}
  end

  @impl Phoenix.LiveView
  def handle_event("dismiss_toast", %{"id" => id}, socket) do
    {:noreply, assign(socket, toasts: Examples.dismiss(socket.assigns.toasts, "notices", id))}
  end

  def handle_event("toggle_values", _params, socket) do
    {:noreply, assign(socket, show_values: not socket.assigns.show_values)}
  end

  # Everything else belongs to the shell — the ⌘K palette's `search`. Defining
  # any clause here replaces the one `docs_live_view` installed, so the rest has
  # to be handed back explicitly rather than silently disappearing.
  def handle_event(event, params, socket), do: super(event, params, socket)

  # A declared attribute always has a default, even when that default is `nil`.
  defp default(attr) do
    case Keyword.fetch(attr.opts, :default) do
      {:ok, value} -> inspect(value)
      :error -> "—"
    end
  end

  defp values(attr) do
    case Keyword.get(attr.opts, :values) do
      nil -> nil
      list -> Enum.map_join(list, ", ", &inspect/1)
    end
  end

  # A slot with no attributes reports them as `nil` rather than as an empty
  # list, and `Enum.map_join/3` has an opinion about that.
  defp slot_attrs(slot), do: List.wrap(slot.attrs)
end
