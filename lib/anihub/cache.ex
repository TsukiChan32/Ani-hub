defmodule Anihub.Anilist.Cache do
  use GenServer

  @cache_table :anihub_anilist_cache
  @lock_table :anihub_anilist_cache_locks

  @lock_timeout_ms :timer.seconds(15)
  @wait_interval_ms 50

  # --------------------------------------------------
  # START
  # --------------------------------------------------

  def start_link(_opts) do
    GenServer.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  # --------------------------------------------------
  # PUBLIC API
  # --------------------------------------------------

  def fetch(key, ttl_ms, fun) do
    case lookup(key) do
      {:ok, value} ->
        value

      :miss ->
        fetch_missing(key, ttl_ms, fun)
    end
  end

  # --------------------------------------------------
  # GENSERVER
  # --------------------------------------------------

  @impl true
  def init(:ok) do
    :ets.new(
      @cache_table,
      [
        :named_table,
        :public,
        :set,
        read_concurrency: true,
        write_concurrency: true
      ]
    )

    :ets.new(
      @lock_table,
      [
        :named_table,
        :public,
        :set,
        write_concurrency: true
      ]
    )

    {:ok, %{}}
  end

  # --------------------------------------------------
  # CACHE MISS
  # --------------------------------------------------

  defp fetch_missing(key, ttl_ms, fun) do
    if acquire_lock(key) do
      try do
        # Ktoś mógł wypełnić cache pomiędzy lookup/1
        # a zdobyciem locka.
        case lookup(key) do
          {:ok, value} ->
            value

          :miss ->
            value = fun.()

            maybe_put(key, value, ttl_ms)

            value
        end
      after
        release_lock(key)
      end
    else
      wait_for_value(key, ttl_ms, fun)
    end
  end

  # --------------------------------------------------
  # WAIT FOR ANOTHER REQUEST
  # --------------------------------------------------

  defp wait_for_value(key, ttl_ms, fun) do
    Process.sleep(@wait_interval_ms)

    case lookup(key) do
      {:ok, value} ->
        value

      :miss ->
        cond do
          lock_active?(key) ->
            wait_for_value(key, ttl_ms, fun)

          true ->
            # Proces, który miał locka, zakończył pracę
            # albo nie zapisał wyniku, np. dostał 429.
            # Próbujemy ponownie.
            fetch_missing(key, ttl_ms, fun)
        end
    end
  end

  # --------------------------------------------------
  # LOOKUP
  # --------------------------------------------------

  defp lookup(key) do
    now = now_ms()

    case :ets.lookup(@cache_table, key) do
      [{^key, value, expires_at}]
      when expires_at > now ->
        {:ok, value}

      [{^key, _value, _expires_at}] ->
        :ets.delete(@cache_table, key)
        :miss

      [] ->
        :miss
    end
  end

  # --------------------------------------------------
  # STORE
  # --------------------------------------------------

  # Cache only successful AniList responses.
  #
  # We specifically DON'T want to cache:
  #
  #   {:error, {:http_error, 429, ...}}
  #
  # because otherwise a temporary AniList rate limit could remain
  # cached for the whole TTL.
  defp maybe_put(key, {:ok, _} = value, ttl_ms) do
    expires_at = now_ms() + ttl_ms

    :ets.insert(
      @cache_table,
      {key, value, expires_at}
    )

    :ok
  end

  defp maybe_put(_key, _value, _ttl_ms) do
    :ok
  end

  # --------------------------------------------------
  # SINGLE-FLIGHT LOCK
  # --------------------------------------------------

  defp acquire_lock(key) do
    expires_at = now_ms() + @lock_timeout_ms

    case :ets.insert_new(
           @lock_table,
           {key, expires_at}
         ) do
      true ->
        true

      false ->
        remove_stale_lock(key)

        :ets.insert_new(
          @lock_table,
          {key, expires_at}
        )
    end
  end

  defp release_lock(key) do
    :ets.delete(@lock_table, key)
    :ok
  end

  defp lock_active?(key) do
    now = now_ms()

    case :ets.lookup(@lock_table, key) do
      [{^key, expires_at}] when expires_at > now ->
        true

      [{^key, _expires_at}] ->
        :ets.delete(@lock_table, key)
        false

      [] ->
        false
    end
  end

  defp remove_stale_lock(key) do
    now = now_ms()

    case :ets.lookup(@lock_table, key) do
      [{^key, expires_at}] when expires_at <= now ->
        :ets.delete(@lock_table, key)

      _ ->
        :ok
    end
  end

  # --------------------------------------------------
  # TIME
  # --------------------------------------------------

  defp now_ms do
    System.monotonic_time(:millisecond)
  end
end
