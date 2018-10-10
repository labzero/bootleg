defmodule Bootleg.Role do
  @moduledoc false
  @enforce_keys [:name, :hosts, :user]
  defstruct [:name, :hosts, :user, options: []]

  alias Bootleg.Host

  def combine_hosts(%Bootleg.Role{} = role, hosts) do
    %Bootleg.Role{role | hosts: Host.combine_uniq(role.hosts ++ hosts)}
  end

  def define(name, hosts, options \\ []) do
    opts = Keyword.merge(default_options(), options)

    hosts =
      hosts
      |> List.wrap()
      |> Enum.map(&Host.init(&1, opts))

    new_role = %Bootleg.Role{
      name: name,
      user: opts[:user],
      hosts: [],
      options: opts
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

  def default_options do
    [user: System.get_env("USER")]
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
