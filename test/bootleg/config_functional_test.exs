defmodule Bootleg.ConfigFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  import ExUnit.CaptureIO

  setup %{hosts: [host]} do
    use Bootleg.Config
    role :app, host.ip, port: host.port, user: host.user, password: host.password,
      silently_accept_hosts: true, workspace: "workspace"
  end

  test "remote/2" do
    use Bootleg.Config

    task :remote_functional_test do
      out = remote :app do
        "echo Hello World!"
        "uname -a"
      end
      assert [[{:ok, [stdout: "Hello World!\n"], 0, _}], [{:ok, [stdout: uname], 0, _}]] = out
      assert Regex.match?(~r/Linux$/mu, uname)
    end

    task :remote_functional_single_line_test do
      out = remote :app do
        "echo a single line!"
      end
      assert [{:ok, [stdout: "a single line!\n"], 0, _}] = out
    end

    task :remote_functional_stderr_test do
      out = remote :app do
        "echo a single line! && echo foo 1>&2"
      end
      assert [{:ok, [stdout: "a single line!\n", stderr: "foo\n"], 0, _}] = out
    end

    capture_io(fn ->
      assert :ok = invoke :remote_functional_test
      assert :ok = invoke :remote_functional_single_line_test
      assert :ok = invoke :remote_functional_stderr_test
    end)
  end

  test "remote/2 fails remotely" do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config

    task :remote_functional_negative_test do
      remote :app do
        "false"
      end
    end

    capture_io(fn ->
      assert_raise SSHError, fn -> invoke :remote_functional_negative_test end
    end)
  end
end
