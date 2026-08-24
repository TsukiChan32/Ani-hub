defmodule AnihubWeb.PageController do
  use AnihubWeb, :controller

  alias Anihub.Library

  def home(conn, _params) do
    {:ok, anime} = Anihub.Anilist.trending()

    render(conn, :home, anime: anime)
  end

  def search(conn, %{"q" => query}) do
    {:ok, anime} = Anihub.Anilist.search(query)

    render(conn, :search, anime: anime, query: query)
  end

  def library(conn, _params) do
    scope = conn.assigns.current_scope
    entries = Library.list_anime_entries(scope)

    ids = Enum.map(entries, & &1.anilist_id)

    {:ok, anime} = Anihub.Anilist.anime_by_ids(ids)

    anime_by_id =
      Map.new(anime, fn item ->
        {item["id"], item}
      end)

    library =
      entries
      |> Enum.map(fn entry ->
        %{
          entry: entry,
          anime: anime_by_id[entry.anilist_id]
        }
      end)
      |> Enum.group_by(fn item ->
        item.entry.status
      end)

    render(conn, :library, library: library)
  end
end
