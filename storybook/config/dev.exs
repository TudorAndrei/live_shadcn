import Config

# A demo application on a developer's machine and in a headless browser. It
# serves no data and holds no session worth protecting, so the key below is a
# fixed development value rather than a secret.
config :storybook, StorybookWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4100")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: String.duplicate("live_shadcn_storybook_development_only", 2),
  watchers: []

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
