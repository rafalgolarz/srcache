defmodule SRCache.Cache.Manager do
  @moduledoc """
  Manages dynamically created GenServers.
  Each cached function will be created as a child of DynamicSupervisor.
  """

  require Logger

  use DynamicSupervisor
  alias SRCache.Cache.Refreshener
  alias SRCache.Cache.Registry, as: Functions

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  @spec init(any) ::
          {:ok,
           %{
             extra_arguments: list,
             intensity: non_neg_integer,
             max_children: :infinity | non_neg_integer,
             period: pos_integer,
             strategy: :one_for_one
           }}
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add(key, fun, ttl, refresh_interval) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Refreshener,
       %{
         key: key,
         function: fun,
         ttl: ttl,
         refresh_interval: refresh_interval
       }}
    )
  end

  @spec remove(any) :: :ok
  def remove(key) do
    key |> Functions.lookup() |> terminate()
  end

  defp terminate([{pid, _}]) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  defp terminate(_) do
    Logger.error("Key not found")
  end

  @spec count :: %{
          active: non_neg_integer,
          specs: non_neg_integer,
          supervisors: non_neg_integer,
          workers: non_neg_integer
        }
  def count() do
    DynamicSupervisor.count_children(__MODULE__)
  end

  @spec list :: [{:undefined, :restarting | pid, :supervisor | :worker, :dynamic | [atom]}]
  def list() do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
