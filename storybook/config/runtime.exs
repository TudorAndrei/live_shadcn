import Config

# A release starts no endpoint unless it is told to, so the Dockerfile sets
# PHX_SERVER and `mix phx.server` sets it for you in development.
if System.get_env("PHX_SERVER") do
  config :storybook, StorybookWeb.Endpoint, server: true
end

if config_env() == :prod do
  secret =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      SECRET_KEY_BASE is not set.

      The storybook holds no data and no session worth protecting, but LiveView
      still signs its socket with this, so it has to be a real value:

          mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4100")

  config :storybook, StorybookWeb.Endpoint,
    secret_key_base: secret,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    check_origin: ["//#{host}", "//localhost"]
end
