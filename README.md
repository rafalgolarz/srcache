# SRCache

# Periodic Self-Rehydrating Cache 

A periodic self-rehydrating cache with ablity to register 0-arity functions (each under a new key) that will recompute periodically and store their results in the cache for fast-access instead of being called every time the values are needed.


This caching mechanism is useful when we are working with data that doesn't change often and its benefits become clear if computing the data is expensive in the first place.

As an example, let's consider an application that makes multiple queries to an external service returning weather data categorized by cities. Because of API rate-limiting, the queries could take multiple minutes or more to execute but the weather can be fast changing. In order to have fresh data in the cache at all times, we can register a function like `:weather_data` with a `ttl` ("time to live") of 1 hour and a `refresh_interval` of 10 minutes. Similarly to a [cron job](https://en.wikipedia.org/wiki/Cron), the function is executed at a given interval of time and the cache holds the most recently computed value and can provide it as needed.



### Sample code execution:

1. Register a new function:

```
iex▶ SRCache.Cache.register_function(fn -> {:ok, "result2"} end, :weather3, 60000, 50000)

06:30:10.564 [debug] [msg: "Registering new function", fun: #Function<43.3316493/0 in :erl_eval.expr/6>, key: :weather3, ttl: 60000, refresh_interval: 50000]
 
06:30:10.569 [info] Starting function: weather3.
 
06:30:10.569 [info] [msg: "Function added to registry", count_registered: 1]
 
06:30:10.569 [info] Function weather3 completed successfullly!
:ok
```
Function gets exectured and stores the result for 60000 milliseconds. The next call will take place in 50000 milliseconds. When that happens the fresh result gets cached and expire_at will gets updated.


2. Get the cached result

```
iex▶ SRCache.Cache.get(:weather3)

06:36:57.455 [info] Get cached result of weather3 function
{:ok, "result2"}

```

3. When attempting to get the result before the function finish its execution, we'll get time out.

```
{:error, :timeout}
```