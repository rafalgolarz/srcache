defmodule SRCache.MixProject do
  use Mix.Project

  def project do
    [
      app: :srcache,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SRCache.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false}
    ]
  end
end
