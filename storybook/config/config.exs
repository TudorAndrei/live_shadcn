import Config

config :storybook, StorybookWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [html: StorybookWeb.ErrorHTML], layout: false],
  pubsub_server: Storybook.PubSub,
  live_view: [signing_salt: "live_shadcn_storybook"]

config :phoenix, :json_library, Jason

# GitHub's release download can exceed Erlang's HTTP chunk-header limit.
# The upstream mirror serves the same artifacts with pinned checksum checks.
config :mdex_native, artifact_source: :cloudflare

config :logger, :console, format: "$time $metadata[$level] $message\n"

import_config "#{config_env()}.exs"
