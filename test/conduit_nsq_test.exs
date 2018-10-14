defmodule ConduitNsqTest do
  use ExUnit.Case
  doctest ConduitNsq

  test "greets the world" do
    assert ConduitNsq.hello() == :world
  end
end
