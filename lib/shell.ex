defmodule Bootleg.Shell do
    @moduledoc "Provides Bash related tools for use in `Bootleg.Strategies`."

  def run(cmd, args, opts \\ []) do
    System.cmd(cmd, args, set_defaults(opts))
  end

  defp set_defaults(opts) do
    Keyword.merge(opts, default_opts())
  end

  defp default_opts, do: [stderr_to_stdout: true]
end



