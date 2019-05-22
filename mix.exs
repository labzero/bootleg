defmodule Bootleg.Mixfile do
  use Mix.Project

  @version "0.11.0"
  @source "https://github.com/labzero/bootleg"
  @homepage "https://labzero.github.io/bootleg/"

  def project do
    [
      app: :bootleg,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs,
        dialyzer: :dev,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.circle": :test,
        "coveralls.html": :test
      ],
      dialyzer: [plt_add_apps: [:mix, :sshkit, :ex_unit]],
      docs: docs(),
      aliases: aliases(),
      description: description(),
      deps: deps(),
      package: package(),
      source_url: @source,
      homepage_url: @homepage
    ]
  end

  def application do
    [extra_applications: [:logger, :sshkit, :mix]]
  end

  defp deps do
    [
      {:sshkit, "0.1.0"},
      {:ssh_client_key_api, "~> 0.2.1"},
      {:credo, "~> 0.10", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.18", only: [:docs], runtime: false},
      {:excoveralls, "~> 0.10", only: [:test]},
      {:mock, "~> 0.3.0", only: [:test]},
      {:junit_formatter, "~> 2.0", only: [:test]},
      {:temp, "~> 0.4.3", only: [:test]}
    ]
  end

  defp aliases do
    [
      docs: [&mkdocs/1, "docs"]
    ]
  end

  defp mkdocs(_args) do
    docs = Path.join([File.cwd!(), "script", "docs", "docs.sh"])
    {_, 0} = System.cmd(docs, ["build"], into: IO.stream(:stdio, :line))
  end

  defp docs do
    [
      source_url: @source,
      homepage_url: @homepage,
      main: "home"
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
