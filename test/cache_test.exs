defmodule SRCache.CacheTest do
  @moduledoc false
  use ExUnit.Case

  alias SRCache.Cache

  describe "register_function/4" do
    test "register new function successfullly" do
      assert :ok == Cache.register_function(fn -> {:ok, :data} end, :storm, 1000, 10)
    end

    test "check if function is already registered" do
      Cache.register_function(fn -> {:ok, :data} end, :weather, 1000, 10)

      assert {:error, :already_registered} ==
               Cache.register_function(fn -> {:ok, :data} end, :weather, 1000, 10)
    end

    test "check if function param is actually a function" do
      assert {:error, :fun_must_be_a_function} ==
               Cache.register_function("a", :weather, 1000, 10)
    end

    test "check if function param is actually a function with 0 arity" do
      assert {:error, :fun_must_be_0_arity_function} ==
               Cache.register_function(fn x -> {:ok, x} end, :weather, 1000, 10)
    end

    test "check if ttl is integer" do
      assert {:error, :ttl_must_be_integer} ==
               Cache.register_function(fn -> {:ok, :data} end, :weather, 10.9, 10)
    end

    test "check if ttl is grreater than zero" do
      assert {:error, :ttl_must_be_greater_than_zero} ==
               Cache.register_function(fn -> {:ok, :data} end, :weather, 0, 10)
    end

    test "check if refresh interval is integer" do
      assert {:error, :refresh_interval_must_be_integer} ==
               Cache.register_function(fn -> {:ok, :data} end, :weather, 100, 0.1)
    end

    test "check if refresh interval is smaller than ttl" do
      assert {:error, :refresh_interval_must_be_smaller_than_ttl} ==
               Cache.register_function(fn -> {:ok, :data} end, :weather1, 1, 10)
    end
  end
end
