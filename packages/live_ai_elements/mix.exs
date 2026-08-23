defmodule LiveAiElements.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @source_url "https://github.com/TudorAndrei/live_shadcn"

  def project do
    [
      app: :live_ai_elements,
      version: @version,
      elixir: "~> 1.17",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "AI Elements for Phoenix LiveView: streaming message parts, reasoning, and tool calls.",
      package: package(),
      docs: docs()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:live_shadcn, dep_spec("live_shadcn", "~> 0.1")},
      {:phoenix_live_view, "~> 1.2"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp dep_spec(name, version) do
    if System.get_env("HEX_PUBLISH"), do: version, else: [path: "../#{name}"]
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
