defmodule Bootleg.Tasks.InvokeTaskTest do
  use Bootleg.TestCase
  alias Bootleg.Fixtures

  setup do
    location = Fixtures.inflate_project(:bootstraps)

    location
    |> List.wrap
    |> Kernel.++(["config", "deploy.exs"])
    |> Path.join()
    |> File.write("""
      use Bootleg.Config
      task :hello, do: IO.puts "HELLO WORLD!"
    """, [:write])

    %{project_location: location}
  end

  test "mix bootleg.invoke", %{project_location: location} do
    shell_env = [{"BOOTLEG_PATH", File.cwd!}]
    cmd_options = [env: shell_env, cd: location]

    assert {_, 0} = System.cmd("mix", ["deps.get"], cmd_options)
    assert {out, 0} = System.cmd("mix", ["bootleg.invoke", "hello"], cmd_options)
    assert String.match?(out, ~r/HELLO WORLD!/)

    assert {_, 0} = System.cmd("mix", ["bootleg.invoke", "unknown"], cmd_options)

    assert {out, 1} = System.cmd("mix", ["bootleg.invoke"], cmd_options)
    assert String.match?(out, ~r/You must supply a task identifier as the first argument\./)
  end
end
