defmodule SRCache.Cache.ManagerTest do
  @moduledoc false
  use ExUnit.Case

  alias SRCache.Cache.Manager

  test "add/4" do
    {:ok, pid} =
      Manager.add(
        :forecast,
        fn ->
          {:ok, "raining"}
        end,
        1000,
        100
      )

    assert is_pid(pid)
  end

  test "remove/1" do
    {:ok, pid} =
      Manager.add(
        :remove_me,
        fn ->
          {:ok, "raining"}
        end,
        1000,
        100
      )

    assert :ok == Manager.remove(:remove_me)
  end

  test "list/0" do
    Manager.add(
      :count_me_in,
      fn ->
        {:ok, "raining"}
      end,
      1000,
      100
    )

    assert is_list(Manager.list())
  end
end
