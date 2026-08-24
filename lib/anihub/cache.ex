defmodule Anihub.Anilist.Cache do
  use GenServer

  @table :anihub_anilist_cache

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch(key, ttl_ms, fun) do
    case lookup(key) do
      {:ok, value} ->
        value

      :miss ->
        value = fun.()
        put(key, value, ttl_ms)
        value
    end
  end

  @impl true
  def init(:ok) do
    :ets.new(
      @table,
      [
        :named_table,
        :public,
        :set,
        read_concurrency: true
      ]
    )

    {:ok, %{}}
  end

  defp lookup(key) do
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(@table, key) do
      [{^key, value, expires_at}] when expires_at > now ->
        {:ok, value}

      [{^key, _value, _expires_at}] ->
        :ets.delete(@table, key)
        :miss

      [] ->
        :miss
    end
  end

  defp put(key, value, ttl_ms) do
    expires_at =
      System.monotonic_time(:millisecond) + ttl_ms

    :ets.insert(
      @table,
      {key, value, expires_at}
    )

    :ok
  end
end
