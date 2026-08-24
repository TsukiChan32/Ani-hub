defmodule AnihubWeb.HomeLive do
  use AnihubWeb, :live_view

  alias Anihub.Anilist
  alias Anihub.Library

  @impl true
  def mount(_params, _session, socket) do
    anime =
      case Anilist.trending() do
        {:ok, anime} ->
          anime

        {:error, reason} ->
          IO.inspect(reason, label: "ANILIST TRENDING ERROR")
          []
      end

    watching = load_watching(socket.assigns.current_scope)

    socket =
      socket
      |> assign(:anime, anime)
      |> assign(:hero, List.first(anime))
      |> assign(:watching, watching)

    socket =
      if anime == [] do
        put_flash(socket, :error, "Could not load trending anime")
      else
        socket
      end

    {:ok, socket}
  end

  defp load_watching(nil), do: []

  defp load_watching(scope) do
    entries =
      scope
      |> Library.list_anime_entries()
      |> Enum.filter(fn entry ->
        to_string(entry.status) == "watching"
      end)

    ids = Enum.map(entries, & &1.anilist_id)

    anime =
      case Anilist.anime_by_ids(ids) do
        {:ok, anime} ->
          anime

        {:error, reason} ->
          IO.inspect(reason, label: "ANILIST LIBRARY ERROR")
          []
      end

    anime_by_id =
      Map.new(anime, fn item ->
        {item["id"], item}
      end)

    entries
    |> Enum.map(fn entry ->
      %{
        entry: entry,
        anime: anime_by_id[entry.anilist_id]
      }
    end)
    |> Enum.reject(fn item ->
      is_nil(item.anime)
    end)
  end

  defp progress_value(nil), do: 0

  defp progress_value(value) when is_integer(value),
    do: value

  defp progress_value(value) when is_float(value),
    do: trunc(value)

  defp progress_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {number, _} -> number
      :error -> 0
    end
  end

  defp progress_value(_), do: 0
end
