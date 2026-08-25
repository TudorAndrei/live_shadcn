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
      aliases: aliases(),
      dialyzer: [
        plt_local_path: "priv/plts",
        plt_core_path: "priv/plts",
        # Mix tasks call `Mix.raise/1` and `Mix.shell/0`, and ExUnit is only in
        # the test build. Without both, dialyzer reports every one of those
        # calls as an unknown function.
        plt_add_apps: [:mix, :ex_unit]
      ],
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
      # `:dev` is here because `credo` wants it there, and a dependency cannot
      # be scoped more narrowly than the things that depend on it.
      {:jason, "~> 1.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ] ++ checks()
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

  # Static analysis. None of it ships — every entry is `runtime: false` and
  # scoped to dev and test, so an application that depends on this package gets
  # none of it. `.credo.exs` at the repository root says what runs, and it
  # excludes everything the pipeline generates.
  defp checks do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 2.1", only: [:dev, :test], runtime: false},
      # A credo plugin. It ports the high-signal `credence` rules, so it stands
      # in for that package too.
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
    ]
  end

  # Every check that reads the code without running it. `--config-file` points
  # at the repository root, because five copies of a rule set is five chances
  # for them to disagree.
  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --config-file ../../.credo.exs",
        "deps.audit",
        "dialyzer"
      ]
    ]
  end
end
