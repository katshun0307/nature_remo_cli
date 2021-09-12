defmodule NatureRemoCliTest do
  use ExUnit.Case
  doctest NatureRemoCli

  test "greets the world" do
    assert NatureRemoCli.hello() == :world
  end
end
