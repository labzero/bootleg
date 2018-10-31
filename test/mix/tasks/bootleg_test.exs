defmodule Mix.Tasks.BootlegTest do
  use ExUnit.Case
  alias Mix.Tasks.Bootleg

  test "provide a list of available bootleg mix tasks" do
    Bootleg.run([])
    assert_received {:mix_shell, :info, ["Bootleg v" <> _]}
    assert_received {:mix_shell, :info, ["mix bootleg.build" <> _]}
    assert_received {:mix_shell, :info, ["mix bootleg.init" <> _]}
    assert_received {:mix_shell, :info, ["mix bootleg.invoke" <> _]}
    assert_received {:mix_shell, :info, ["mix bootleg.update" <> _]}
  end
end
