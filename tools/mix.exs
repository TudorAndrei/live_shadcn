defmodule LiveShadcnTools.MixProject do
  use Mix.Project

  # Maintainer-only codegen pipeline. Never published to hex.
  def project do
    [
      app: :live_shadcn_tools,
      version: "0.1.0-dev",
      elixir: "~> 1.17",
      start_permanent: false,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_local_path: "priv/plts",
        plt_core_path: "priv/plts",
        # Mix tasks call `Mix.raise/1` and `Mix.shell/0`, and ExUnit is
        # only in the test build. Without both, dialyzer reports every
        # one of those calls as an unknown function.
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  # One command for every check that reads the code without running it.
  #
  # `--config-file` points at the repository root, because five copies of a rule
  # set is five chances for them to disagree.
  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --config-file ../.credo.exs",
        "deps.audit",
        "dialyzer"
      ]
    ]
  end

  def application, do: [extra_applications: [:logger, :inets, :ssl]]

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"}
    ] ++ checks()
  end

  # Static analysis. None of it ships, and none of it runs at runtime.
  #
  # `mix check` runs the lot. See `.credo.exs` at the repository root for what
  # is enabled and, more usefully, what is switched off and why.
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
end
