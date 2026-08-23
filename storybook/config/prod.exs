import Config

# The storybook is deployed as a public demo. Everything that varies by
# environment — the host, the port, the signing key — is read at runtime in
# `runtime.exs`, so one image runs anywhere.
config :storybook, StorybookWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info
