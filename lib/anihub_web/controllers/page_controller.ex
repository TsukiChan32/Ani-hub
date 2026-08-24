defmodule AnihubWeb.PageController do
  use AnihubWeb, :controller

  def home(conn, _params) do
    {:ok, anime} = Anihub.Anilist.trending()

    render(conn, :home, anime: anime)
  end

  def search(conn, %{"q" => query}) do
    {:ok, anime} = Anihub.Anilist.search(query)

    render(conn, :search, anime: anime, query: query)
  end

  def show(conn, %{"id" => id}) do
    id = String.to_integer(id)

    case Anihub.Anilist.anime(id) do
      {:ok, %{"Media" => anime}} ->
        render(conn, :show, anime: anime)

      {:error, :not_found} ->
        send_resp(conn, 404, "Anime not found")
    end
  end
end
