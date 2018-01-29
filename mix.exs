defmodule SimpleQueue.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_queue,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        maintainers: ["vtm"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/vtm9/simple_queue"},
        description: "A simple persistent queues"
      ]
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
      {:ex_doc, github: "elixir-lang/ex_doc", override: true, only: :dev}
    ]
  end
end
