defmodule Bootleg.FunctionalCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  alias Bootleg.UI

  import Bootleg.FunctionalCaseHelpers
  require Logger

  @image "bootleg-test-sshd"
  @cmd "/usr/sbin/sshd"
  @args ["-D", "-e"]

  @user "me"
  @pass "pass"

  using args do
    quote do
      @moduletag :functional
      unless unquote(args)[:async] do
        setup do
          Bootleg.Config.Agent.wait_cleanup()
        end
      end
    end
  end

  setup tags do
    count = Map.get(tags, :boot, 1)
    verbosity = Map.get(tags, :ui_verbosity, :silent)
    role_opts = Map.get(tags, :role_opts, %{})
    key_passphrase = Map.get(tags, :key_passphrase, "")

    conf = %{image: @image, cmd: @cmd, args: @args}
    hosts = Enum.map(1..count, fn _ -> init(boot(conf), passphrase: key_passphrase) end)

    if Map.get(tags, :verbose, System.get_env("TEST_VERBOSE")) do
      Logger.info("started docker hosts: #{inspect(hosts, pretty: true)}")
    end

    unless Map.get(tags, :leave_vm, System.get_env("TEST_LEAVE_CONTAINER")) do
      on_exit(fn -> kill(hosts) end)
    end

    current_verbosity = UI.verbosity()

    if current_verbosity != verbosity do
      Application.put_env(:bootleg, :verbosity, verbosity)
      on_exit(fn -> Application.put_env(:bootleg, :verbosity, current_verbosity) end)
    end

    {:ok, hosts: hosts, role_opts: role_opts}
  end

  def boot(%{image: image, cmd: cmd, args: args} = config) do
    id =
      Docker.run!(
        ["--rm", "--publish-all", "--detach", "-v", "#{File.cwd!()}:/project"],
        image,
        cmd,
        args
      )

    ip = Docker.host()

    port =
      "port"
      |> Docker.cmd!([id, "22/tcp"])
      |> String.split(":")
      |> List.last()
      |> String.to_integer()

    Map.merge(config, %{id: id, ip: ip, port: port})
  end

  @dialyzer {:no_return, init: 1, init: 2}
  @spec init(binary, []) :: %{}
  def init(host, options \\ []) do
    adduser!(host, @user)
    chpasswd!(host, @user, @pass)
    passphrase = Keyword.get(options, :passphrase, "")
    {public_key, private_key} = keygen!(host, @user, passphrase)

    key_path = Temp.mkdir!("docker-key")
    public_key_path = Path.join(key_path, "id_rsa.pub")
    private_key_path = Path.join(key_path, "id_rsa")
    File.write(public_key_path, public_key)
    File.write(private_key_path, private_key)
    File.chmod!(private_key_path, 0o600)

    Map.merge(host, %{
      user: @user,
      password: @pass,
      public_key: public_key,
      public_key_path: public_key_path,
      private_key: private_key,
      private_key_path: private_key_path
    })
  end

  def kill(hosts) do
    running = Enum.map(hosts, &Map.get(&1, :id))
    killed = Docker.kill!(running)
    diff = running -- killed
    if Enum.empty?(diff), do: :ok, else: {:error, diff}
  end
end
