defmodule StorybookWeb.PreviewLive do
  @moduledoc """
  One example on a page of its own.

  The page carries nothing but the component: no navigation, no headings that
  are not the component's. That is deliberate. `mix ui.verify` runs axe-core
  against this page, and a violation has to belong to the component rather than
  to the chrome around it.
  """

  use StorybookWeb, :live_view

  alias StorybookWeb.Examples

  defmodule NotFound do
    @moduledoc "An example nobody defined. A 404, not a blank page."
    defexception [:message, plug_status: 404]
  end

  @impl Phoenix.LiveView
  def mount(%{"component" => component, "example" => id}, _session, socket) do
    case Examples.fetch(component, id) do
      {:ok, example} ->
        {:ok,
         socket
         |> assign(component: component, example: example, page_title: example.title)
         |> assign(Examples.page_assigns())}

      :error ->
        raise NotFound, message: "no #{component} example called #{id}"
    end
  end

  @impl Phoenix.LiveView
  def handle_event("dismiss_toast", %{"id" => id}, socket) do
    {:noreply, assign(socket, toasts: Examples.dismiss(socket.assigns.toasts, "notices", id))}
  end

  # One round trip to reveal a secret, which is the whole design of the
  # environment variables component: the page is given the value when it asks,
  # and not before.
  def handle_event("toggle_values", _params, socket) do
    {:noreply, assign(socket, show_values: not socket.assigns.show_values)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id={"preview-#{@component}-#{@example.id}"} data-preview={@component}>
      <%!-- A page needs a heading, and a heading level may not be skipped. The
            accordion's own headings are `h3`, which Base UI documents, so the
            page supplies the two above them. None of them is shown. --%>
      <h1 class="sr-only">{@component}</h1>
      <h2 class="sr-only">{@example.title}</h2>
      {@example.render.(assigns)}
    </div>
    """
  end
end
