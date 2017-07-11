defmodule Bootleg.Role do
  @moduledoc ""
  @enforce_keys [:name, :hosts, :user]
  defstruct [:name, :hosts, :user, options: []]

  alias Bootleg.Host

  def combine_hosts(%__MODULE__{} = role, hosts) do
    %__MODULE__{role | hosts: Host.combine_uniq(role.hosts ++ hosts)}
  end
end
