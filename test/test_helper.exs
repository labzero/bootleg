unless Docker.ready? do
  IO.puts """
  It seems like Docker isn't running?

  Please check:

  1. Docker is installed: `docker version`
  2. On OS X and Windows: `docker-machine start`
  3. Environment is set up: `eval $(docker-machine env)`
  """

  exit({:shutdown, 1})
end

Docker.build!("bootleg-test-sshd", "test/support/docker")

ExUnit.configure formatters: [JUnitFormatter, ExUnit.CLIFormatter]
ExUnit.start()
