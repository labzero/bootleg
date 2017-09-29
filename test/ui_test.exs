defmodule Bootleg.UITest do
  use Bootleg.TestCase, async: false

  import ExUnit.CaptureIO

  alias Bootleg.UI
  alias SSHKit.{Context, Host}

  doctest UI

  setup do
    %{
      conn: %Context{
        path: ".",
        hosts: [
          %Host{name: "localhost.1", options: []},
          %Host{name: "localhost.2", options: []}
        ]
      },
      verbosity: :info
    }
  end

  test "puts restricts output based on verbosity level" do
    # :info is "set" as the verbosity level
    assert :ok == UI.puts(:info, "", :info)
    assert :ok == UI.puts(:warning, "", :info)
    assert nil == UI.puts(:debug, "", :info)
    assert :ok == UI.puts(:error, "", :info)

    # :warning is set now
    assert nil == UI.puts(:info, "", :warning)
    assert :ok == UI.puts(:warning, "", :warning)
    assert nil == UI.puts(:debug, "", :warning)
    assert :ok == UI.puts(:error, "", :warning)

    # :error is set now
    assert nil == UI.puts(:info, "", :error)
    assert nil == UI.puts(:warning, "", :error)
    assert nil == UI.puts(:debug, "", :error)
    assert :ok == UI.puts(:error, "", :error)

    # :debug is set now and should unrestrict output
    assert :ok == UI.puts(:info, "", :debug)
    assert :ok == UI.puts(:warning, "", :debug)
    assert :ok == UI.puts(:debug, "", :debug)
    assert :ok == UI.puts(:error, "", :debug)

    # :silent is "set" as the verbosity level
    assert nil == UI.puts(:info, "", :silent)
    assert nil == UI.puts(:warning, "", :silent)
    assert nil == UI.puts(:debug, "", :silent)
    assert nil == UI.puts(:error, "", :silent)
  end

  test "verbosity is validated and defaults to :info" do
    assert :info == UI.verbosity(:foo)
  end

  test "puts helpers can be used as shorthand" do
    assert capture_io(fn ->
      UI.info("foo", :info)
    end) == "foo\n"

    assert capture_io(fn ->
      UI.warn("bar", :warning)
    end) == "bar\n"

    assert capture_io(fn ->
      UI.debug("baz", :debug)
    end) == "baz\n"

    assert capture_io(fn ->
      UI.error("caz", :error)
    end) == "caz\n"
  end

  # SSH-specific output tests

  describe "ssh puts upload" do
    @tag ui_color: false
    test "without coloring", %{conn: conn} do
      local_path = "/tmp/foo"
      remote_path = "/tmp/bar"

      assert capture_io(fn ->
        UI.puts_upload(conn, local_path, remote_path)
      end) == "[localhost.1] UPLOAD /tmp/foo -> ./tmp/bar\n[localhost.2] UPLOAD /tmp/foo -> ./tmp/bar\n"
    end

    @tag ui_color: true
    test "with color", %{conn: conn} do
      local_path = "/tmp/foo"
      remote_path = "/tmp/bar"
      assert capture_io(fn ->
        UI.puts_upload(conn, local_path, remote_path)
      end) == "\e[0m\e[1m\e[32m[localhost.1] \e[0m\e[33mUPLOAD \e[0m/tmp/foo\e[0m\e[33m -> \e[0m./tmp/bar\n\e[0m\e[0m\e[1m\e[32m[localhost.2] \e[0m\e[33mUPLOAD \e[0m/tmp/foo\e[0m\e[33m -> \e[0m./tmp/bar\n\e[0m"
    end
  end

  describe "ssh puts download" do
    @tag ui_color: false
    test "without color", %{conn: conn} do
      remote_path = "/tmp/bar"
      local_path = "/tmp/foo"

      assert capture_io(fn ->
        UI.puts_download(conn, remote_path, local_path)
      end) == "[localhost.1] DOWNLOAD ./tmp/bar -> /tmp/foo\n[localhost.2] DOWNLOAD ./tmp/bar -> /tmp/foo\n"
    end

    @tag ui_color: true
    test "with color", %{conn: conn} do
      remote_path = "/tmp/bar"
      local_path = "/tmp/foo"

      assert capture_io(fn ->
        UI.puts_download(conn, remote_path, local_path)
      end) == "\e[0m\e[1m\e[32m[localhost.1] \e[0m\e[33mDOWNLOAD \e[0m./tmp/bar\e[0m\e[33m -> \e[0m/tmp/foo\n\e[0m\e[0m\e[1m\e[32m[localhost.2] \e[0m\e[33mDOWNLOAD \e[0m./tmp/bar\e[0m\e[33m -> \e[0m/tmp/foo\n\e[0m"
    end
  end

  describe "ssh puts send to context" do
    @tag ui_color: false
    test "without color", %{conn: conn} do
      assert capture_io(fn ->
        UI.puts_send(conn, "ls -l")
      end) == "[localhost.1] ls -l\n[localhost.2] ls -l\n"
    end

    @tag ui_color: true
    test "with color", %{conn: conn} do
      assert capture_io(fn ->
        UI.puts_send(conn, "ls -l")
      end) == "\e[0m\e[1m\e[32m[localhost.1] \e[0mls -l\n\e[0m\e[0m\e[1m\e[32m[localhost.2] \e[0mls -l\n\e[0m"
    end
  end

  describe "ssh puts send to host" do
    @tag ui_color: false
    test "without color" do
      assert capture_io(fn ->
        UI.puts_send(%SSHKit.Host{name: "localhost.1"}, "hostname")
      end) == "[localhost.1] hostname\n"
    end

    @tag ui_color: true
    test "with color" do
      assert capture_io(fn ->
        UI.puts_send(%SSHKit.Host{name: "localhost.1"}, "hostname")
      end) == "\e[0m\e[1m\e[32m[localhost.1] \e[0mhostname\n\e[0m"
    end
  end

  test "ssh puts receive list", %{conn: conn} do
    data = [{:ok, [stdout: "hello world!"], 0, List.first(conn.hosts)}]
    assert capture_io(fn ->
      UI.puts_recv(data)
    end) == "\e[0m\e[1m\e[34m[localhost.1] \e[0mhello world!\n\e[0m"
  end

  test "ssh puts receive tuple", %{conn: conn} do
    data = {:ok, [stdout: "hello world!"], 0, List.first(conn.hosts)}
    assert capture_io(fn ->
      UI.puts_recv(data)
    end) == "\e[0m\e[1m\e[34m[localhost.1] \e[0mhello world!\n\e[0m"
  end

  test "ssh puts receive from context", %{conn: conn} do
    assert capture_io(fn ->
      UI.puts_recv(conn, "hello world!")
    end) == "\e[0m\e[1m\e[34m[localhost.1] \e[0mhello world!\n\e[0m\e[0m\e[1m\e[34m[localhost.2] \e[0mhello world!\n\e[0m"
  end

  test "ssh puts receive from host", %{conn: conn} do
    host = List.first(conn.hosts)
    assert capture_io(fn ->
      UI.puts_recv(host, "hello world!")
    end) == "\e[0m\e[1m\e[34m[localhost.1] \e[0mhello world!\n\e[0m"
  end

  test "ssh puts does not molest UTF-8 data", %{conn: conn} do
    file = File.read!("./test/fixtures/encoding/utf8.data")
    host = List.first(conn.hosts)
    out = capture_io(fn ->
      UI.puts_recv(host, file)
    end)
    size = byte_size(out)
    char_out = String.to_charlist(out)
    assert Enum.count(char_out, fn codepoint -> codepoint === 8216 end) == 2000
    assert Enum.count(char_out, fn codepoint -> codepoint === 8217 end) == 2000
    assert size == 273_036, "Received data not in expected form."
  end
end
