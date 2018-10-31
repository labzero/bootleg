# Welcome

Bootleg is an Elixir application that provides simple and maintainable deployment and server automation for [Distillery](https://github.com/bitwalker/distillery) releases.

Many different deployment scenarios are supported with one common set of commands. Where possible, native Elixir and Erlang solutions have been used, and shell commands avoided. Bootleg leans heavily upon the wonderful [SSHKit.ex](https://github.com/bitcrowd/sshkit.ex) library to provide SSH capabilities.

Out of the box, we support building your application on your local machine, within a Docker image, or on remote build servers using Git push or pull operations.
