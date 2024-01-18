defmodule RegistryDemoTest do
  use ExUnit.Case
  doctest RegistryDemo

  test "greets the world" do
    assert RegistryDemo.hello() == :world
  end
end
