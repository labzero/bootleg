defmodule Bootleg.Fixtures do
  @moduledoc false

  def identity_path do
    Path.relative_to_cwd("test/fixtures/identity_rsa")
  end
end
