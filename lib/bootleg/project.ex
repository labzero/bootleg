defmodule Bootleg.Project do
  @moduledoc ""
  @enforce_keys [:app_name, :app_version]
  defstruct [:app_name, :app_version]
end
