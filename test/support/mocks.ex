defmodule Bootleg.Mocks do
  @moduledoc false

  defmodule SSH do
    @moduledoc false
    @mocks Bootleg.SSH

    def init(hosts, options \\ []) do
      send(self(), {@mocks, :init, [hosts, options]})
      :conn
    end

    def run(conn, cmd) do
      send(self(), {@mocks, :run, [conn, cmd]})
      :conn
    end

    def run!(:conn, cmd) do
      send(self(), {@mocks, :"run!", [:conn, cmd]})
      [{:ok, [normal: "stdout"], 0, %SSHKit.Host{name: "localhost"}}]
    end

    def upload(conn, local, remote, options \\ []) do
      send(self(), {@mocks, :upload, [conn, local, remote, options]})
      :ok
    end

    def download(conn, local, remote, options \\ []) do
      send(self(), {@mocks, :download, [conn, local, remote, options]})
      :ok
    end

  end

  defmodule SSHKit do
    @moduledoc false

    def run(_conn, "nonexistant_command") do
      [{:ok, [normal: "File not found"], 1}]
    end

    def run(_conn, _cmd) do
      [{:ok, [normal: "Badgers"], 0, %{name: "localhost"}}]
    end

    def download(_conn, "nonexistant_file", _options) do
      [{:error, "cant open remote file"}]
    end

    def download(_conn, _remote_path, _options) do
      [:ok]
    end

    def upload(_conn, "nonexistant_file", _options) do
      [{:error, "cant open local file"}]
    end

    def upload(_conn, _local_path, _options) do
      [:ok]
    end

    defmodule Host do
      @moduledoc false

      defstruct [:name, :options]
    end

    defmodule SSH do
      @moduledoc false
      @mocks SSHKit.SSH

      def connect(name, options) do
        send(self(), {@mocks, :connect, [name, options]})
        {:ok, :conn}
      end

      def run(_conn, _command, _options) do
        {:ok, [normal: "Badgers"], 0}
      end
    end
  end

  defmodule Git do
    @moduledoc false
    @mocks Bootleg.Git

    def remote(args, options \\ []) do
      send(self(), {@mocks, :remote, [args, options]})
      :ok
    end

    def push(args, options \\ []) do
      send(self(), {@mocks, :push, [args, options]})
      {"", 0}
    end
  end

  defmodule Shell do
    @moduledoc false
    @mocks Bootleg.Shell

    def run(cmd, args, opts \\ []) do
      send(self(), {@mocks, :run, [cmd, args, opts]})
      :ok
    end
  end

  defmodule FileReader do
    @moduledoc false

    def mkdir_p("404"), do: {:error, :enoent}
    def mkdir_p(_), do: :ok
    def exists?("404.tar.gz"), do: false
    def exists?(_), do: true
    def rename(_, "read_only_folder/1.0.0.tar.gz"), do: {:error, :enoent}
    def rename(_, _), do: :ok
    def ls!("releases"), do: ["1.0.0.tar.gz", "1.0.1.tar.gz"]
    def ls!("big_release_folder") do
      ["1.0.0.tar.gz", "1.0.1.tar.gz", "1.0.2.tar.gz", "1.0.3.tar.gz", "1.04.tar.gz"]
    end
    def ls!(_), do: []
    def rm(_), do: :ok
  end
end
