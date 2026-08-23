defmodule LiveShadcnTools.MixProject do
  use Mix.Project

  # Maintainer-only codegen pipeline. Never published to hex.
  def project do
    [
      app: :live_shadcn_tools,
      version: "0.1.0-dev",
      elixir: "~> 1.17",
      start_permanent: false,
      deps: deps()
    ]
  end

  def application, do: [extra_applications: [:logger, :inets, :ssl]]

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
