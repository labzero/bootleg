defmodule SSHErrorTest do
  use Bootleg.TestCase, async: true
  doctest SSHError

  test "exception([cmd, output, status, host])" do
    error = SSHError.exception(["cmd", [stdout: "output"], "status", %{name: "host"}])
    assert %SSHError{status: "status",
              host: %{name: "host"},
              message: "Command exited on host with non-zero status (status)\n     cmd: cmd\n  stdout: output\n",
              output: [stdout: "output"]} == error
  end

  test "exception([err, host]) when err is an atom" do
    error = SSHError.exception([:an_error, %{name: "host"}])
    assert %SSHError{status: :an_error,
              host: %{name: "host"},
              message: "SSHKit returned an internal error on host: :an_error"
              } = error
  end

  test "exception([err, host]) when err is a string" do
    error = SSHError.exception(["an error", %{name: "host"}])
    assert %SSHError{status: "an error",
              host: %{name: "host"},
              message: "SSHKit returned an internal error on host: \"an error\""
              } = error
  end
end
