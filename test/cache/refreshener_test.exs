defmodule SRCache.Cache.RefreshenerTest do
  @moduledoc false
  use ExUnit.Case

  alias SRCache.Cache.Refreshener

  setup do
    params = %{
      key: :testme,
      function: fn -> {:ok, "tested"} end,
      ttl: 1000,
      refresh_interval: 100
    }

    {:ok, pid} = Refreshener.start_link(params)
    %{pid: pid, params: params}
  end

  test "start_link/1", %{pid: pid} do
    assert is_pid(pid)
  end
end
