defmodule BootlegTest do
  use ExUnit.Case, async: true
  doctest Bootleg

  test "check_config" do
    # configs are just maps (for now)
    assert {:error, _} = Bootleg.check_config(%{}, ~w(hello world))
    assert :ok == Bootleg.check_config(%{host: "test"}, ~w(host))
  end
end
