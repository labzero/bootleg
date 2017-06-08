defmodule Bootleg do
  @moduledoc """
  Makes building and deploying your app easier then getting a prohibition-era drink.

  Integrating `Bootleg` into your application is a matter of setting up an appropriate configuration. See
  `Bootleg.Config` for details on configuration.
  """
  alias Bootleg.Config

  @doc """
  Check for the presence and non-nil value of one or more terms in a config.
  Used by individual strategies to enforce required settings.
  """
  @spec check_config(struct(), [String.t]) :: :ok | {:error, String.t}
  def check_config(config, terms) do
    missing = Enum.filter(terms,
                          &(Map.get(config, String.to_atom(&1), nil) == nil))

    if Enum.count(missing) > 0 do
      missing_quoted =
        missing
        |> Enum.map(fn(x) -> "\"#{x}\"" end)
        |> Enum.join(", ")
      {:error, "This strategy requires #{missing_quoted} to be configured"}
    else
      :ok
    end
  end

  @doc "Alias for `Bootleg.Config.init/0`."
  @spec config :: %Bootleg.Config{}
  def config do
    Config.init()
  end
end
