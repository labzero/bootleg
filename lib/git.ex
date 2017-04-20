defmodule Bootleg.Git do
  
  alias Bootleg.Shell

  def remote(args) do
    git("remote", args)
  end

  def push(args) do
    git("push", args)
  end
    
  defp git(cmd, args) do
    Shell.run("git", [cmd | args])
  end
  
end