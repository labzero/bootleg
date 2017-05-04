defmodule SSHError do
  defexception [:message, :status, :output]

  def exception([cmd, output, status]) do
    msg = "Command exited with non-zero status (#{status})\n"
      <> format("cmd", cmd)
      <> cond_format("stdout", :normal, output)
      <> cond_format("stderr", :stderr, output)

    %SSHError{message: msg, status: status, output: output}
  end

  @padding 8
  defp format(key, value) do
    String.pad_leading(key, @padding)
      <> ": "
      <> String.trim_trailing(value)
      <> "\n"
  end

  defp cond_format(key, atom, output) do
    case List.keymember?(output, atom, 0) do
      true -> format(key, output[atom])
      _ -> ""
    end
  end
end
