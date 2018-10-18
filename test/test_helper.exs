unless System.get_env("TEST_LEAVE_TEMP"), do: Temp.track!()

skip_functional_tests =
  ExUnit.configuration()
  |> Keyword.get(:exclude)
  |> Enum.member?(:functional)

unless skip_functional_tests do
  unless Docker.ready?() do
    IO.puts("""
    It seems like Docker isn't running?

    Please check:

    1. Docker is installed: `docker version`
    2. On OS X and Windows: `docker-machine start`
    3. Environment is set up: `eval $(docker-machine env)`
    """)

    exit({:shutdown, 1})
  end

  Docker.build!("bootleg-test-sshd", "test/support/docker")
end

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
