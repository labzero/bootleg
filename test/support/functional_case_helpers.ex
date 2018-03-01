defmodule Bootleg.FunctionalCaseHelpers do
  @moduledoc false

  def adduser!(%{id: id} = _host, username) do
    Docker.exec!([], id, "adduser", ["-D", username])
  end

  def addgroup!(%{id: id} = _host, groupname) do
    Docker.exec!([], id, "addgroup", [groupname])
  end

  def add_user_to_group!(%{id: id} = _host, username, groupname) do
    Docker.exec!([], id, "addgroup", [username, groupname])
  end

  def chpasswd!(%{id: id} = _host, username, password) do
    command = "echo #{username}:#{password} | chpasswd 2>&1"
    Docker.exec!([], id, "sh", ["-c", command])
  end

  def keygen!(%{id: id} = _host, username) do
    Docker.exec!([], id, "sh", [
      "-c",
      "ssh-keygen -b 1024 -f /tmp/#{username} -N '' -C \"#{username}@$(hostname)\""
    ])

    Docker.exec!([], id, "sh", [
      "-c",
      "cat /tmp/#{username}.pub > /home/#{username}/.ssh/authorized_keys"
    ])

    Docker.exec!([], id, "sh", ["-c", "cat /tmp/#{username}"])
  end
end
