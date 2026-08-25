defmodule StorybookWeb do
  @moduledoc """
  Entrypoints for the demo application's web layer.
  """

  def static_paths, do: ~w(assets favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  @doc """
  A page that carries nothing but what it renders.

  `PreviewLive` is the one that matters: `mix ui.verify` runs axe-core against
  those pages, so a violation there has to belong to the component rather than
  to any navigation around it.
  """
  def live_view do
    quote do
      use Phoenix.LiveView, layout: {StorybookWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  @doc "A page inside the documentation shell: sidebar, header, content column."
  def docs_live_view do
    quote do
      use Phoenix.LiveView, layout: {StorybookWeb.Layouts, :docs}

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: StorybookWeb.Endpoint,
        router: StorybookWeb.Router,
        statics: StorybookWeb.static_paths()
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      alias Phoenix.LiveView.JS

      unquote(verified_routes())
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
