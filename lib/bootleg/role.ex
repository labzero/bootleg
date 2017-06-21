defmodule Bootleg.Role do
  @moduledoc ""
  @enforce_keys [:name, :hosts]
  defstruct [:name, :hosts, options: []]
end
