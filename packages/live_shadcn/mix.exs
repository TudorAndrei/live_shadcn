defmodule LiveShadcn.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/TudorAndrei/live_shadcn"

  def project do
    [
      app: :live_shadcn,
      version: @version,
      elixir: "~> 1.17",
      elixirc_options: [warnings_as_errors: true],
      # The registry is the source `mix ui.add` copies. Compiling it here is
      # what proves every generated component still builds and renders.
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "shadcn/ui components for Phoenix LiveView, generated from the shadcn registry.",
      package: package(),
      docs: docs()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp elixirc_paths(:test), do: ["lib", "priv/registry", "test/support"]
  defp elixirc_paths(_env), do: ["lib", "priv/registry"]

  defp deps do
    [
      {:live_base, dep_spec("live_base", "~> 0.1")},
      {:phoenix_live_view, "~> 1.2"},
      # The default icon set. Optional, so an application that draws its icons
      # from somewhere else pulls in nothing it does not use.
      {:lucide_icons, "~> 2.3", optional: true},
      {:floki, ">= 0.36.0", only: :test},
      # LiveView serialises a JS command with the host application's JSON
      # library. Tests render those commands, so they need one; a host
      # application already has it.
      {:jason, "~> 1.4", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  # Hex refuses to publish a package that carries a path dependency.
  # Local work uses the path; `HEX_PUBLISH=1 mix hex.publish` uses the version.
  defp dep_spec(name, version) do
    if System.get_env("HEX_PUBLISH"), do: version, else: [path: "../#{name}"]
  end

  # Apache-2.0 asks that the licence and the NOTICE travel with the work, so
  # both are in the package rather than only in the repository.
  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/packages/live_shadcn/CHANGELOG.md"
      },
      # `usage-rules.md` is the condensed contract an LLM reads before writing
      # against this package. It only helps if it ships, which is what this line
      # is for. See https://usage-rules.hexdocs.pm.
      files: ~w(lib priv .formatter.exs mix.exs README.md CHANGELOG.md LICENSE NOTICE
                usage-rules.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        "Generated components": ~r/LiveShadcn\.UI\./
      ]
    ]
  end
end
