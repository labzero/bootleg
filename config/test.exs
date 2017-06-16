use Mix.Config

# test doubles
# config :bootleg, ssh: Bootleg.Mocks.SSH
config :bootleg, git: Bootleg.Mocks.Git
config :bootleg, shell: Bootleg.Mocks.Shell
config :bootleg, sshkit: Bootleg.Mocks.SSHKit
config :bootleg, file_reader: Bootleg.Mocks.FileReader
