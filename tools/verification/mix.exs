defmodule LiveShadcnVerification.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_shadcn_verification,
      version: "0.1.0-dev",
      elixir: "~> 1.17",
      start_permanent: false,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --warnings-as-errors"
      ]
    ]
  end

  def application, do: [extra_applications: [:logger, :crypto]]

  defp deps do
    [{:jason, "~> 1.4"}]
  end
end
