defmodule Bootleg.Role do
  @moduledoc ""
  @enforce_keys [:name, :hosts, :user]
  defstruct [:name, :hosts, :user, options: []]

  alias Bootleg.{Host, SSH}

  def combine_hosts(%Bootleg.Role{} = role, hosts) do
    %Bootleg.Role{role | hosts: Host.combine_uniq(role.hosts ++ hosts)}
  end

  def define(name, hosts, options \\ []) do
    # user is in the role options for scm

    user = Keyword.get(options, :user, System.get_env("USER"))

    ssh_options =
      Enum.filter(options, &(Enum.member?(SSH.supported_options(), elem(&1, 0)) == true))

    # identity needs to be present in both options lists
    role_options =
      (options -- ssh_options)
      |> Keyword.put(:user, user)
      |> Keyword.put(:identity, ssh_options[:identity])
      |> Keyword.get_and_update(:identity, fn val ->
        if val || Keyword.has_key?(ssh_options, :identity) do
          {val, val || ssh_options[:identity]}
        else
          :pop
        end
      end)
      |> elem(1)

    hosts =
      hosts
      |> List.wrap()
      |> Enum.map(&Host.init(&1, ssh_options, role_options))

    new_role = %Bootleg.Role{
      name: name,
      user: user,
      hosts: [],
      options: role_options
    }

    role =
      :roles
      |> Bootleg.Config.Agent.get()
      |> Keyword.get(name, new_role)
      |> combine_hosts(hosts)

    Bootleg.Config.Agent.merge(
      :roles,
      name,
      role
    )
  end

  @doc false
  @spec split_roles_and_filters(atom | keyword) :: {[atom], keyword}
  def split_roles_and_filters(role) do
    role
    |> List.wrap()
    |> Enum.split_while(fn term -> !is_tuple(term) end)
  end

  @doc false
  @spec unpack_role(atom | keyword) :: tuple
  def unpack_role(role) do
    wrapped_role = List.wrap(role)

    if Enum.any?(wrapped_role, fn role -> role == :all end) do
      quote do: Keyword.keys(Bootleg.Config.Agent.get(:roles))
    else
      quote do: unquote(wrapped_role)
    end
  end
end
