defmodule StorybookWeb.IndexLive do
  @moduledoc """
  The front page: what this is, and how to install it.

  It used to render every example on one page. That made a fixed-position
  toaster sit over the whole listing, and it meant the page grew by one
  component each time the pipeline learned to read another. The components are
  one page each now, under `/docs/:component`.
  """

  use StorybookWeb, :docs_live_view

  alias StorybookWeb.Docs
  alias StorybookWeb.Examples

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-semibold tracking-tight">live_shadcn</h1>
    <p class="mt-3 text-muted-foreground">
      shadcn/ui for Phoenix LiveView. Every component is generated from the shadcn
      registry — the class strings, the <code class="text-xs">data-slot</code>
      names and the data-attribute contract all come from upstream, and no
      generated line is edited by hand.
    </p>

    <section class="mt-10">
      <h2 class="text-lg font-medium">Install</h2>
      <pre class="mt-3 overflow-x-auto rounded-md border bg-muted p-4 text-xs"><code>mix ui.add button dialog select</code></pre>
      <p class="mt-2 text-sm text-muted-foreground">
        The components are copied into your application under your own namespace,
        with a version stamp. <code class="text-xs">mix ui.sync</code>
        reports upstream drift and refuses to overwrite a file you have edited.
      </p>
    </section>

    <section class="mt-10">
      <h2 class="text-lg font-medium">{@count} components</h2>
      <ul class="mt-4 grid grid-cols-2 gap-x-6 gap-y-1 sm:grid-cols-3">
        <li :for={component <- @components}>
          <.link
            navigate={~p"/docs/#{component}"}
            class="text-sm underline-offset-4 hover:underline"
          >
            {Docs.title(component)}
          </.link>
        </li>
      </ul>
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    components = Examples.components()

    {:ok,
     assign(socket,
       components: Enum.sort(components),
       count: length(components),
       page_title: "live_shadcn"
     )}
  end
end
