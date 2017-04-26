defmodule BootlegTest do
  use ExUnit.Case, async: true
  doctest Bootleg

  test "check_config" do
    assert Bootleg.check_config(%Bootleg.BuildConfig{}, ~w()) == :ok

    # strategies can require keys to be set (non-nil)
    config = %Bootleg.BuildConfig{host: nil}
    assert {:error, _} = Bootleg.check_config(config, ~w(host))

    config = %Bootleg.BuildConfig{host: "acme.local"}
    assert :ok = Bootleg.check_config(config, ~w(host))

    # configs are just maps (for now)
    assert {:error, _} = Bootleg.check_config(%{}, ~w(hello world))
    assert :ok == Bootleg.check_config(%{host: "test"}, ~w(host))
  end
end
