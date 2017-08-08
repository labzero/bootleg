defmodule Bootleg.Mixfile do
  use Mix.Project

  @version "0.3.0"
  @source "https://github.com/labzero/bootleg"

  def project do
    [app: :bootleg,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_deps: :transitive, plt_add_apps: [:mix, :sshkit]],
      docs: [source_ref: "v#{@version}", main: "readme", extras: ["README.md"]],
      description: description(),
      deps: deps(),
      package: package()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :sshkit, :mix]]
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
      {:sshkit, "0.0.3"},
      {:ssh_client_key_api, "0.0.1"},
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:excoveralls, "~> 0.6", only: :test},
      {:bunt, "~> 0.2.0"},
      {:mock, "~> 0.2.0", only: :test},
      {:junit_formatter, "~> 1.3", only: :test},
      {:temp, "~> 0.4.3", only: :test}
    ]
  end

  defp description do
    "Simple deployment and server automation for Elixir."
  end

  defp package do
    [maintainers: ["labzero", "Brien Wankel", "Ned Holets", "Rob Adams"],
     licenses: ["MIT"],
     links: %{"GitHub" => @source}]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]
end
