defmodule DgraphEx.Mixfile do
  use Mix.Project

  def project do
    [
      app: :dgraph_ex,
      version: "0.1.5",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      source_url: "https://github.com/elbow-jason/dgraph_ex",
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      extra_applications: []
      # mod: {DgraphEx.Application, []},
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.12.0"},
      {:ok, github: "sunny-g/ok"},
      {:poison, "~> 3.1"},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.7.2", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mix_test_watch, "~> 0.6", only: :dev},
      {:mox, "~> 0.1", only: :test}
    ]
  end

  defp description do
    """
    A database wrapper and model layer for dgraph.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :dgraph_ex,
      files: ["lib", "mix.exs", "README*", "LICENSE*", ".iex.exs"],
      maintainers: ["Jason Goldberger"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/elbow-jason/dgraph_ex"}
    ]
  end

  defp aliases() do
    [
      {:"test.all", [&test_unit/1, &test_integration/1]},
      {:"test.integration", [&test_integration/1]},
      {:"test.unit", [&test_unit/1]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_unit(_) do
    Mix.shell.cmd(
      "mix test --exclude integration --color",
      env: [{"MIX_ENV", "test"}]
    )
  end

  defp test_integration(_) do
    Mix.shell.cmd(
      "mix test --only integration --color",
      env: [{"MIX_ENV", "test"}]
    )
  end
end
