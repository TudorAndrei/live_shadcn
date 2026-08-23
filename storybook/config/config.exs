import Config

config :storybook, StorybookWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [html: StorybookWeb.ErrorHTML], layout: false],
  pubsub_server: Storybook.PubSub,
  live_view: [signing_salt: "live_shadcn_storybook"]

config :phoenix, :json_library, Jason

config :logger, :console, format: "$time $metadata[$level] $message\n"

import_config "#{config_env()}.exs"
