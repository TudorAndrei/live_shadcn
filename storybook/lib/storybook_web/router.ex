defmodule StorybookWeb.Router do
  use StorybookWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StorybookWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", StorybookWeb do
    pipe_through :browser

    live "/", IndexLive
    live "/docs/:component", DocsLive

    # Deliberately outside the documentation shell. `mix ui.verify` runs
    # axe-core against these pages, so they carry nothing but the component:
    # a violation has to belong to what is being verified.
    live "/preview/:component/:example", PreviewLive
  end

  # What there is to check. The browser suite reads this rather than being told
  # twice which components have examples.
  scope "/", StorybookWeb do
    pipe_through :api

    get "/previews.json", PreviewController, :index
  end
end
