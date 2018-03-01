defmodule Bootleg.Env do
  @moduledoc false
  alias Bootleg.{Config, UI}

  def deploy_config, do: Path.join(["config", "deploy.exs"])
  def deploy_config_dir, do: Path.join(["config", "deploy"])

  def load(env) do
    loaded =
      deploy_config_dir()
      |> Path.join("#{env}.exs")
      |> Config.load()

    unless :ok == loaded do
      UI.warn(
        "You are running in the `#{Config.env()}` bootleg " <>
          "environment but there is no configuration defined for that environment. " <>
          "Create one at `#{deploy_config_dir()}` if you want to do additional " <>
          "customization."
      )
    end
  end

  @doc false
  @spec get_available() :: [binary]
  defp get_available do
    [deploy_config_dir(), "*.exs"]
    |> List.flatten()
    |> Path.join()
    |> Path.wildcard()
    |> Enum.map(&Path.basename(&1, ".exs"))
  end

  @doc false
  @spec available?(atom) :: boolean
  def available?(env) when is_atom(env) do
    available?(Atom.to_string(env))
  end

  @doc false
  @spec available?(binary) :: boolean
  def available?(env) when is_binary(env) do
    Enum.member?(get_available(), env)
  end
end
