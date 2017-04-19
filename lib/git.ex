defmodule Bootleg.Git do
  
  alias Bootleg.Shell

  def remote(args, options \\ []) do
    git("remote", args, options)
  end

  def push(args, options \\ []) do
    git("push", args, options)
  end
    
  defp git(cmd, args, options \\ []) do
    Shell.run("git", [cmd | args], options)
  end
  
end