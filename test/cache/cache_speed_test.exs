defmodule SRCache.CacheSpeedTest do
  @moduledoc false
  use ExUnit.Case

  alias SRCache.Cache

  describe "get/2" do
    test "register and get" do
      Cache.register_function(
        fn ->
          Process.sleep(1000)
          {:ok, :sleep}
        end,
        :sleep,
        1000,
        10
      )

      Cache.register_function(
        fn ->
          {:ok, :quick}
        end,
        :quick,
        1000,
        10
      )

      assert Cache.get(:sleep) == {:error, :timeout}
      assert Cache.get(:quick) == {:ok, {:ok, :quick}}
    end

    test "call function when expired" do
      Cache.register_function(
        fn ->
          {:ok, Enum.random(1..100)}
        end,
        :expired,
        10,
        1
      )

      Process.sleep(50)
      res1 = Cache.get(:expired)

      Process.sleep(50)
      res2 = Cache.get(:expired)

      assert res1 != res2
    end
  end
end
