defmodule Bootleg.Strategies.Deploy.RemoteSSHTest do
  use ExUnit.Case, async: false
  import Mock

  doctest Bootleg.Strategies.Deploy.RemoteSSH

  test "init" do
    with_mocks([
      {Bootleg.SSH,
       [],
       [start: fn() -> :ok end,
        connect: fn(_h,_u,_i) -> :conn end,
        run: fn(_con, _cmd) -> :conn end,
        safe_run: fn(_con, _dir, _cmd) -> :conn end]},
      {File,
       [],
       [open: fn(f) -> {:ok, f} end]}
    ]) do
        config = %Bootleg.Config{
                    app: "bootleg",
                    deploy: %Bootleg.DeployConfig{
                      identity: "identity",
                      workspace: "workspace",
                      host: "host",
                      user: "user"}}

      Bootleg.Strategies.Deploy.RemoteSSH.init(config)
      assert called Bootleg.SSH.start()
      assert called Bootleg.SSH.connect(config.deploy.host, config.deploy.user, config.deploy.identity)
      assert called Bootleg.SSH.run(:conn, "
      set -e
      mkdir -p #{config.deploy.workspace}
      ")
    end
  end

end
