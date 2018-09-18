defmodule Bootleg.Mixfile do
  use Mix.Project

  @version "0.7.0"
  @source "https://github.com/labzero/bootleg"
  @homepage "https://labzero.github.io/bootleg/"

  def project do
    [
      app: :bootleg,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_deps: :transitive, plt_add_apps: [:mix, :sshkit]],
      docs: [source_ref: "release-#{@version}", main: "readme", extras: ["README.md"]],
      description: description(),
      deps: deps(),
      package: package(),
      source_url: @source,
      homepage_url: @homepage
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
      {:sshkit, "0.1.0"},
      {:ssh_client_key_api, "~> 0.1"},
      {:credo, "~> 0.8.0", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:excoveralls, "~> 0.6", only: :test},
      {:mock, "~> 0.3.0", only: :test},
      {:junit_formatter, "~> 2.0", only: :test},
      {:temp, "~> 0.4.3", only: :test}
    ]
  end

  defp description do
    "Simple deployment and server automation for Elixir."
  end

  defp package do
    [
      maintainers: ["labzero", "Brien Wankel", "Ned Holets", "Rob Adams"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source, "Homepage" => @homepage}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "web"]
  defp elixirc_paths(_), do: ["lib", "web"]
end
