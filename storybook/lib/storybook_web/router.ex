defmodule StorybookWeb.Router do
  use StorybookWeb, :router

  import PhoenixStorybook.Router

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
    live "/preview/:component/:example", PreviewLive
  end

  # What there is to check. The browser suite reads this rather than being told
  # twice which components have examples.
  scope "/", StorybookWeb do
    pipe_through :api

    get "/previews.json", PreviewController, :index
  end

  # The asset routes are declared first: the storybook itself claims
  # `/storybook/*`, and a route it shadows is a route that never matches.
  scope "/" do
    storybook_assets("/storybook/assets")
  end

  scope "/" do
    pipe_through :browser

    live_storybook("/storybook",
      backend_module: StorybookWeb.Storybook,
      assets_path: "/storybook/assets"
    )
  end
end
