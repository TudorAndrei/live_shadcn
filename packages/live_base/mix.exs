defmodule LiveBase.MixProject do
  use Mix.Project

  @version "0.1.0"
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

  # Apache-2.0 asks that the licence and the NOTICE travel with the work, so
  # both are in the package rather than only in the repository.
  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/packages/live_base/CHANGELOG.md"
      },
      # `usage-rules.md` is the condensed contract an LLM reads before writing
      # against this package. It only helps if it ships, which is what this line
      # is for. See https://usage-rules.hexdocs.pm.
      files: ~w(lib assets .formatter.exs mix.exs package.json README.md CHANGELOG.md
                LICENSE NOTICE usage-rules.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        Recipes: [
          LiveBase.Disclosure,
          LiveBase.Dialog,
          LiveBase.Popover,
          LiveBase.Menu,
          LiveBase.Listbox,
          LiveBase.Tabs,
          LiveBase.FormControl
        ]
      ]
    ]
  end
end
