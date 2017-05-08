defmodule Bootleg.Mocks do
  @moduledoc false

  defmodule SSH do
    @moduledoc false
    @mocks Bootleg.SSH

    def start do
      send(self(), {@mocks, :start})
      :ok
    end

    def connect(host, user, options) do
      send(self(), {@mocks, :connect, [host, user, options]})
      :conn
    end

    def run(conn, cmd) do
      send(self(), {@mocks, :run, [conn, cmd]})
      :conn
    end

    def run!(conn, cmd) do
      send(self(), {@mocks, :"run!", [conn, cmd]})
      :conn
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
    @mocks SSHKit

    def run(_conn, "nonexistant_command") do
      [{:ok, [normal: "File not found"], 1}]
    end

    def run(_conn, _cmd) do
      [{:ok, [normal: "Badgers"], 0}]
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

    defmodule SSH do
      @moduledoc false
      @mocks SSHKit.SSH

      def connect(name, options) do
        send(self(), {@mocks, :connect, [name, options]})
        {:ok, :conn}
      end

      def run(conn, command, options) do
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

end
