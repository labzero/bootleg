defmodule Bootleg.Git do
  @moduledoc "Provides Git related tools for use in `Bootleg.Strategies`."

  def remote(args, options \\ []) do
    git("remote", args, options)
  end

  def push(args, options \\ []) do
    git("push", args, options)
  end

  defp git(cmd, args, options \\ []) do
    System.cmd("git", [cmd | args], Keyword.merge(options, [stderr_to_stdout: true]))
  end

end
