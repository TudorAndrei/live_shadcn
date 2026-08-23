import Config

config :storybook, StorybookWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4102],
  secret_key_base: String.duplicate("live_shadcn_storybook_test_only_key_ab", 2),
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
