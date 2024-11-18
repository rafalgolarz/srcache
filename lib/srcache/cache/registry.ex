defmodule SRCache.Cache.Registry do
  @moduledoc """
  Registry is a local, decentralized and scalable key-value process storage.
  Each entry in the registry is associated to the process that has registered the key.
  We use :via option for name lookups.
  Each function that we we're going to cache its result,
  will be tracked individually via Registry.
  """

  @spec via_tuple(atom()) :: {:via, Registry, {atom(), atom()}}
  def via_tuple(key) do
    {:via, Registry, {name(), key}}
  end

  @spec registered?(any) :: boolean
  def registered?(key) do
    name()
    |> Registry.lookup(key)
    |> found?()
  end

  @spec found?(any) :: boolean
  def found?([{_pid, _}]), do: true
  def found?(_), do: false

  @spec lookup(any) :: [{pid, any}]
  def lookup(key), do: Registry.lookup(name(), key)

  @spec unregister(any) :: :ok
  def unregister(key), do: Registry.unregister(name(), key)

  @spec count_registered :: non_neg_integer
  def count_registered(), do: Registry.count(name())

  @spec name :: atom()
  def name(), do: :functions_registry
end
