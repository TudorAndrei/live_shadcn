defmodule LiveBase.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @source_url "https://github.com/TudorAndrei/live_shadcn"

  def project do
    [
      app: :live_base,
      version: @version,
      elixir: "~> 1.17",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Headless LiveView behavior primitives. Emits the Base UI data-attribute contract.",
      package: package(),
      docs: docs()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:phoenix_live_view, "~> 1.2"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib assets .formatter.exs mix.exs README.md package.json)
    ]
  end

  defp docs, do: [main: "readme", source_url: @source_url, extras: ["README.md"]]
end
