defmodule Verk.Mixfile do
  use Mix.Project

  @description """
    Verk is a job processing system backed by Redis.
  """

  def project do
    [
      app: :verk,
      version: "1.6.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: Coverex.Task, coveralls: true],
      name: "Verk",
      description: @description,
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:logger, :confex, :jason, :redix, :poolboy],
      env: [node_id: "1", redis_url: "redis://127.0.0.1:6379"]
    ]
  end

  defp deps do
    [
      {:redix, ">= 0.6.0 and < 0.8.0"},
      {:jason, "~> 1.0"},
      {:poolboy, "~> 1.5.1"},
      {:confex, "~> 3.3.0"},
      {:gen_stage, "~> 0.12.1"},
      {:credo, "~> 0.9", only: [:dev, :test]},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "== 0.18.4", only: :dev},
      {:coverex, "== 1.4.13", only: :test},
      {:meck, "~> 0.8.13", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Eduardo Gurgel Pinho", "Alisson Sales"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/edgurgel/verk"}
    ]
  end
end
