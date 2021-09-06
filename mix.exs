defmodule RSS.MixProject do
  use Mix.Project

  def project do
    [
      app: :rss,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RSS.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:aino, path: "./../"},
      {:finch, "~> 0.8"},
      {:sweet_xml, "~> 0.7.1"}
    ]
  end
end
