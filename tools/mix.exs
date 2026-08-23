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

  # phoenix_live_view is here for its HEEx formatter, not to be called.
  # Generated markup has to come out already formatted, or a person will
  # reformat it by hand and the file stops being generated.
  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:phoenix_live_view, "~> 1.2"}
    ]
  end
end
