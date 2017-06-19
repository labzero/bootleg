defmodule Bootleg.ConfigTest do
  use ExUnit.Case, async: true
  alias Bootleg.Config

  doctest Bootleg.Config

  defmacrop roles do
    quote do
      Bootleg.Config.Agent.get(:roles)
    end
  end

  test "role/2" do
    use Bootleg.Config
    assert roles() == []

    role :build, "build.labzero.com"
    result = roles()
    assert [build: %Bootleg.Role{hosts: ["build.labzero.com"], name: :build, options: [user: user]}] = result
    assert user == System.get_env("USER")
  end

  test "role/3" do
    use Bootleg.Config
    assert roles() == []

    role :build, "build.labzero.com", user: "brien"
    assert roles() ==
      [build: %Bootleg.Role{hosts: ["build.labzero.com"], name: :build, options: [user: "brien"]}]
  end

  test "get_role/1" do
    use Bootleg.Config
    role :build, "build.labzero.com"

    result = Config.get_role(:build)
    assert %Bootleg.Role{name: :build, hosts: ["build.labzero.com"]} = result
  end

  test "config/0" do
    use Bootleg.Config
    Bootleg.Config.Agent.put(:config, [foo: :bar])
    assert config() == [foo: :bar]
  end

  test "config/2" do
    use Bootleg.Config
    assert config() == []

    config :build_at, "some path"
    assert config() == [build_at: "some path"]
  end

  test "config file" do
    Code.eval_file(Path.relative_to_cwd("test/fixtures/deploy.exs"))

    roles = Bootleg.Config.Agent.get(:roles)
    config = Bootleg.Config.Agent.get(:config)

    assert %Bootleg.Role{hosts: ["www1.example.com", "www2.example.com"], name: :app, options: [user: user]}
      = roles[:app]
    assert user == System.get_env("USER")
    assert %Bootleg.Role{hosts: ["db.example.com"], name: :db, options: [primary: true, user: "foo"]}
      = roles[:db]
    assert %Bootleg.Role{hosts: ["replacement.example.com"], name: :replace, options: [user: user, bar: :car]}
      = roles[:replace]
    assert user == System.get_env("USER")

    assert config[:build_at] == "some path"
    assert config[:replace_me] == "this"
  end

  test "get_config" do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config

    config :some_key, "some value"

    assert Config.get_config(:some_key) == "some value"
    assert Config.get_config(:another_key) == nil
    assert Config.get_config(:another_key, :bar) == :bar
  end
end
