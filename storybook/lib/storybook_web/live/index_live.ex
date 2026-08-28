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

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-semibold tracking-tight">live_shadcn</h1>
    <p class="mt-3 text-muted-foreground">
      Reviewed shadcn/ui ports for Phoenix LiveView. Class strings,
      <code class="text-xs">data-slot</code>
      names, and state facts stay linked
      to upstream. Maintainers own the HEEx API and behavior.
    </p>

    <%!-- Three packages, said once and up front.

          The list used to be one alphabetical run of every component that has an
          example, which put `Chain Of Thought` between `Carousel` and `Chart`
          and gave no way to tell that one is a dependency and the other is a
          file copied into your application. Two of the entries were even called
          the same thing, because each registry has a `message`. --%>
    <section class="mt-10">
      <h2 class="text-lg font-medium">Three libraries</h2>
      <div class="mt-4 grid gap-3 sm:grid-cols-3">
        <div :for={library <- @libraries} class="rounded-md border p-4">
          <p class="flex items-baseline justify-between gap-2">
            <code class="text-sm font-medium">{library.package}</code>
            <span class="text-xs text-muted-foreground">{library.version}</span>
          </p>
          <p class="mt-2 text-xs text-muted-foreground">{library.blurb}</p>
          <p class="mt-2 text-xs">
            <span :if={library.components != []} class="text-muted-foreground">
              {length(library.components)} documented here
            </span>
            <span :if={library.components == []} class="text-muted-foreground">
              Draws nothing. It is what the other two are built on.
            </span>
          </p>
        </div>
      </div>
    </section>

    <section class="mt-10">
      <h2 class="text-lg font-medium">Install</h2>
      <pre class="mt-3 overflow-x-auto rounded-md border bg-muted p-4 text-xs"><code>mix ui.add button dialog select</code></pre>
      <p class="mt-2 text-sm text-muted-foreground">
        The <code class="text-xs">live_shadcn</code>
        components are copied into your application under your own namespace,
        with a version stamp. <code class="text-xs">mix ui.sync</code>
        reports upstream drift and refuses to overwrite a file you have edited.
        <code class="text-xs">live_ai_elements</code>
        is an ordinary dependency instead — it is not copied in — and
        <code class="text-xs">live_base</code>
        comes with either.
      </p>
    </section>

    <%!-- The same groups as the sidebar, in the same order: one per section of
          the documentation each library publishes. --%>
    <section :for={group <- @groups} class="mt-10">
      <h2 class="text-lg font-medium">
        {group.title}
        <code :if={group.package} class="ml-2 text-sm font-normal text-muted-foreground">
          {group.package}
        </code>
        <span class="ml-2 text-sm font-normal text-muted-foreground">
          {length(group.components)} components
        </span>
      </h2>
      <ul class="mt-4 grid grid-cols-2 gap-x-6 gap-y-1 sm:grid-cols-3">
        <li :for={component <- group.components} class="flex items-center gap-2">
          <.link
            navigate={~p"/docs/#{component}"}
            class="text-sm underline-offset-4 hover:underline"
          >
            {Docs.title(component)}
          </.link>
          <span
            data-component-status={Docs.status(component)}
            class={[
              "rounded-full px-1.5 py-0.5 text-[10px] font-medium capitalize",
              Docs.status(component) == :verified &&
                "bg-green-100 text-green-800 dark:bg-green-950 dark:text-green-300",
              Docs.status(component) == :unverified &&
                "bg-amber-100 text-amber-900 dark:bg-amber-950 dark:text-amber-300",
              Docs.status(component) == :failed &&
                "bg-red-100 text-red-900 dark:bg-red-950 dark:text-red-300"
            ]}
          >
            {Docs.status(component)}
          </span>
        </li>
      </ul>
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       libraries: Docs.libraries(),
       groups: Docs.groups(),
       page_title: "live_shadcn"
     )}
  end
end
