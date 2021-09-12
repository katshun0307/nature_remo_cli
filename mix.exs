defmodule NatureRemoCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :nature_remo_cli,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
      # escript: [main_module: NatureRemoCli]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {NatureRemoCli.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ratatouille, "~> 0.5.0"},
      {:hackney, "~> 1.17"},
      {:jason, ">= 1.0.0"},
      {:tesla, "~> 1.4"}
    ]
  end
end
