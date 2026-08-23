defmodule StorybookWeb.IndexLive do
  @moduledoc """
  What there is to look at: every component, every example, and the storybook.
  """

  use StorybookWeb, :live_view

  alias StorybookWeb.Examples

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, components: Examples.components(), page_title: "live_shadcn")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="text-2xl font-semibold">live_shadcn</h1>
    <p class="text-muted-foreground mt-2 text-sm">
      Generated from the shadcn registry. Nothing on this page was written by hand
      except the example markup.
      <.link navigate={~p"/storybook"} class="underline underline-offset-4">
        Open the storybook
      </.link>
    </p>

    <section :for={component <- @components} class="mt-10">
      <h2 class="text-lg font-medium">{component}</h2>

      <ul class="mt-4 grid gap-6">
        <li :for={example <- Examples.all(component)}>
          <h3 class="text-sm font-medium">
            <.link
              navigate={~p"/preview/#{component}/#{example.id}"}
              class="underline underline-offset-4"
            >
              {example.title}
            </.link>
          </h3>
          <p class="text-muted-foreground mt-1 text-sm">{example.description}</p>
          <div class="mt-3">{example.render.(assigns)}</div>
        </li>
      </ul>
    </section>
    """
  end
end
