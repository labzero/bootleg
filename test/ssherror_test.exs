defmodule SSHErrorTest do
  use ExUnit.Case, async: true
  doctest SSHError

  test "exception([cmd, output, status, host])" do
    error = SSHError.exception(["cmd", [stdout: "output"], "status", %{name: "host"}])
    assert %SSHError{status: "status",
              host: %{name: "host"},
              message: "Command exited on host with non-zero status (status)\n     cmd: cmd\n  stdout: output\n",
              output: [stdout: "output"]} == error
  end
end
