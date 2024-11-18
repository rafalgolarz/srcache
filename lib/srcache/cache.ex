defmodule SRCache.Cache do
  @moduledoc """
  Periodic Self-Rehydrating Cache.
  """
  use GenServer
  require Logger

  @default_timeout 30_000

  @type result ::
          {:ok, any()}
          | {:error, :timeout}
          | {:error, :not_registered}
          | {:error, :timeout_must_be_integer}
          | {:error, :timeout_must_be_greater_than_zero}

  alias SRCache.Cache.Manager
  alias SRCache.Cache.Refreshener
  alias SRCache.Cache.Registry, as: Functions

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl GenServer
  @spec init(any) :: {:ok, any}
  def init(state) do
    Logger.info("*** Ready to cache - let's rock on! ***")
    {:ok, state}
  end

  @doc ~s"""
  Registers a function that will be computed periodically to update the cache.

  Arguments:
    - `fun`: a 0-arity function that computes the value and returns either
      `{:ok, value}` or `{:error, reason}`.
    - `key`: associated with the function and is used to retrieve the stored
    value.
    - `ttl` ("time to live"): how long (in milliseconds) the value is stored
      before it is discarded if the value is not refreshed.
    - `refresh_interval`: how often (in milliseconds) the function is
      recomputed and the new value stored. `refresh_interval` must be strictly
      smaller than `ttl`. After the value is refreshed, the `ttl` counter is
      restarted.

  The value is stored only if `{:ok, value}` is returned by `fun`. If `{:error,
  reason}` is returned, the value is not stored and `fun` must be retried on
  the next run.
  """
  @spec register_function(
          fun :: (any() -> {:ok, any()} | {:error, any()}),
          key :: any,
          ttl :: pos_integer(),
          refresh_interval :: non_neg_integer()
        ) ::
          :ok
          | {:error, :already_registered}
          | {:error, :fun_must_be_a_function}
          | {:error, :fun_must_be_0_arity_function}
          | {:error, :ttl_must_be_integer}
          | {:error, :ttl_must_be_greater_than_zero}
          | {:error, :refresh_interval_must_be_integer}
          | {:error, :refresh_interval_must_be_smaller_than_ttl}
  def register_function(fun, key, ttl, refresh_interval)
      when is_function(fun, 0) and is_integer(ttl) and ttl > 0 and
             is_integer(refresh_interval) and
             refresh_interval < ttl do
    Logger.debug(
      msg: "Registering new function",
      fun: fun,
      key: key,
      ttl: ttl,
      refresh_interval: refresh_interval
    )

    GenServer.call(__MODULE__, {:register_function, fun, key, ttl, refresh_interval})
  end

  def register_function(fun, _key, _ttl, _refresh_interval)
      when not is_function(fun) do
    {:error, :fun_must_be_a_function}
  end

  def register_function(fun, _key, _ttl, _refresh_interval)
      when not is_function(fun, 0) do
    {:error, :fun_must_be_0_arity_function}
  end

  def register_function(_fun, _key, ttl, _refresh_interval)
      when not is_integer(ttl) do
    {:error, :ttl_must_be_integer}
  end

  def register_function(_fun, _key, ttl, _refresh_interval)
      when ttl <= 0 do
    {:error, :ttl_must_be_greater_than_zero}
  end

  def register_function(_fun, _key, _ttl, refresh_interval)
      when not is_integer(refresh_interval) do
    {:error, :refresh_interval_must_be_integer}
  end

  def register_function(_fun, _key, ttl, refresh_interval)
      when refresh_interval >= ttl do
    {:error, :refresh_interval_must_be_smaller_than_ttl}
  end

  @doc ~s"""
  Get the value associated with `key`.

  Details:
    - If the value for `key` is stored in the cache, the value is returned
      immediately.
    - If a recomputation of the function is in progress, the last stored value
      is returned.
    - If the value for `key` is not stored in the cache but a computation of
      the function associated with this `key` is in progress, wait up to
      `timeout` milliseconds. If the value is computed within this interval,
      the value is returned. If the computation does not finish in this
      interval, `{:error, :timeout}` is returned.
    - If `key` is not associated with any function, return `{:error,
      :not_registered}`
  """

  @spec get(any(), pos_integer(), Keyword.t()) :: result
  def get(key, timeout \\ @default_timeout, _opts \\ [])

  def get(key, timeout, _opts) when is_integer(timeout) and timeout > 0 do
    if Functions.registered?(key) do
      {res, ref} = GenServer.call(__MODULE__, {:get, key, timeout})
      parse_res(res, ref)
    else
      Logger.error("Function #{key} not registered.")
      {:error, :not_registered}
    end
  end

  def get(_, timeout, _opts) when not is_integer(timeout) do
    {:error, :timeout_must_be_integer}
  end

  def get(_, timeout, _opts) when not timeout > 0 do
    {:error, :timeout_must_be_greater_than_zero}
  end

  defp parse_res(nil, ref) when is_reference(ref), do: {:error, :timeout}
  defp parse_res(res, nil), do: {:ok, res}

  # ============================================================================

  @impl GenServer
  def handle_call({:register_function, fun, key, ttl, refresh_interval}, _from, cached_funs) do
    key
    |> Functions.registered?()
    |> cache_if_unregistered(key, fun, ttl, refresh_interval, cached_funs)
  end

  @impl GenServer
  def handle_call({:get, key, timeout}, _from, _cached_funs) do
    Logger.info("Get cached result of #{key} function")
    function_result = Refreshener.get(key, timeout)
    {:reply, function_result, function_result}
  end

  # ============================================================================

  @spec default_timeout :: pos_integer()
  def default_timeout(), do: @default_timeout

  defp cache_if_unregistered(true, _key, _fun, _ttl, _refresh_interval, cached_funs) do
    Logger.error(
      msg: "Function already registered!",
      count_registered: Functions.count_registered()
    )

    {:reply, {:error, :already_registered}, cached_funs}
  end

  defp cache_if_unregistered(false, key, fun, ttl, refresh_interval, cached_funs) do
    {:ok, pid} = Manager.add(key, fun, ttl, refresh_interval)

    Logger.info(
      msg: "Function added to registry",
      count_registered: Functions.count_registered()
    )

    if is_map(cached_funs) do
      {:reply, :ok, Map.put(cached_funs, key, pid)}
    else
      {:reply, :ok, %{}}
    end
  end
end
