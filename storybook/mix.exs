defmodule Storybook.MixProject do
  use Mix.Project

  # The demo application. Never published: it exists so a person can look at a
  # component, and so `mix ui.verify` has a real browser to drive.
  def project do
    [
      app: :storybook,
      version: "0.1.0-dev",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      listeners: [Phoenix.CodeReloader],
      start_permanent: false,
      deps: deps(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  # A release strips the docs out of every `.beam` by default, and the storybook
  # reads a component's `@doc` at runtime to show it. Keeping them is the whole
  # reason the storybook is worth deploying.
  defp releases do
    [storybook: [strip_beams: [keep: ["Docs", "Dbgi"]], include_executables_for: [:unix]]]
  end

  def application do
    [mod: {Storybook.Application, []}, extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:live_base, path: "../packages/live_base"},
      {:live_shadcn, path: "../packages/live_shadcn"},
      {:live_ai_elements, path: "../packages/live_ai_elements"},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.2"},
      # live_shadcn keeps the icon set optional. The demo picks the default one.
      {:lucide_icons, "~> 2.3"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},
      # Not test-only: `mix snapshot` uses it to pretty-print generated markup
      # into a golden file a person can read in a diff.
      {:floki, ">= 0.36.0"},
      # Not test-only: lucide_icons needs it at runtime to parse the SVGs.
      {:lazy_html, ">= 0.1.0"}
    ]
  end

  # The style sheets come from `mix ui.fetch`, which puts them in
  # registry/upstream. A build without them is a build with no shadcn styling,
  # so `assets.build` says so rather than producing a silently bare page.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup"],
      "assets.setup": ["cmd --cd assets npm install"],
      "assets.build": ["cmd --cd assets npm run build"],
      "assets.deploy": ["cmd --cd assets npm run deploy", "phx.digest"]
    ]
  end
end
