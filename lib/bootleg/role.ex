defmodule Bootleg.Role do
  @moduledoc ""
  @enforce_keys [:name, :hosts, :user]
  defstruct [:name, :hosts, :user, options: []]
end
