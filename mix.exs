defmodule ConduitNSQ.MixProject do
  use Mix.Project

  def project do
    [
      app: :conduit_nsq,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:conduit, "~> 0.12.7"},
      {:elixir_nsq, github: "conduitframework/elixir_nsq"},
      {:poolboy, "~> 1.5"},
      {:ex_doc, "~> 0.18.0", only: :dev},
      {:dialyxir, "~> 0.4", only: :dev},
      {:junit_formatter, "~> 2.0", only: :test},
      {:excoveralls, "~> 0.5", only: :test},
      {:credo, "~> 0.7", only: [:dev, :test]},
    ]
  end
end
