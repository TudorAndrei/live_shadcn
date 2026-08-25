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
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      # A recorded stream and its golden are data, not a suite to run.
      test_ignore_filters: [&String.starts_with?(&1, "test/fixtures/")],
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
        "AI Elements for Phoenix LiveView: streaming message parts, reasoning, and tool calls.",
      package: package(),
      docs: docs()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:live_shadcn, dep_spec("live_shadcn", "~> 0.1")},
      {:phoenix_live_view, "~> 1.2"},
      # AI Elements renders assistant prose with Streamdown, a markdown renderer
      # built for text that is still arriving. Elixir has that already, so this
      # package uses it rather than writing another one — and keeps it optional,
      # because everybody who renders LLM output already has a renderer.
      # `LiveAiElements.Markdown` is the seam.
      {:phoenix_streamdown, "~> 1.0.0-beta", optional: true},
      # Reading a recorded stream, and writing a golden back. The package itself
      # never decodes anything, so this would be test-only — except that an
      # optional dependency wants it in every environment, and a restriction
      # here refuses to resolve rather than being relaxed.
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ] ++ checks()
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
