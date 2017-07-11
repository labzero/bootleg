defmodule Bootleg.FunctionalCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  import Bootleg.FunctionalCaseHelpers
  require Logger

  @image "bootleg-test-sshd"
  @cmd "/usr/sbin/sshd"
  @args ["-D", "-e"]

  @user "me"
  @pass "pass"

  using do
    quote do
      @moduletag :functional
    end
  end

  setup tags do
    count = Map.get(tags, :boot, 1)

    conf = %{image: @image, cmd: @cmd, args: @args}
    hosts = Enum.map(1..count, fn _ -> init(boot(conf)) end)

    if Map.get(tags, :verbose, System.get_env("TEST_VERBOSE")) do
      Logger.info("started docker hosts: #{inspect hosts, pretty: true}")
    end

    unless Map.get(tags, :leave_vm, System.get_env("TEST_LEAVE_CONTAINER")) do
      on_exit fn -> kill(hosts) end
    end

    {:ok, hosts: hosts}
  end

  def boot(%{image: image, cmd: cmd, args: args} = config) do
    id = Docker.run!(["--rm", "--publish-all", "--detach"], image, cmd, args)

    ip = Docker.host

    port =
      "port"
      |> Docker.cmd!([id, "22/tcp"])
      |> String.split(":")
      |> List.last
      |> String.to_integer

    Map.merge(config, %{id: id, ip: ip, port: port})
  end

  def init(host) do
    adduser!(host, @user)
    chpasswd!(host, @user, @pass)
    private_key = keygen!(host, @user)

    Temp.track!
    private_key_path = Temp.open!(nil, &IO.write(&1, private_key))
    File.chmod!(private_key_path, 0o600)

    Map.merge(host, %{user: @user, password: @pass, private_key: private_key,
      private_key_path: private_key_path})
  end

  def kill(hosts) do
    running = Enum.map(hosts, &(Map.get(&1, :id)))
    killed = Docker.kill!(running)
    diff = running -- killed
    if Enum.empty?(diff), do: :ok, else: {:error, diff}
  end
end
