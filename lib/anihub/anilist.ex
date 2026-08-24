defmodule Anihub.Anilist do
  @endpoint "https://graphql.anilist.co"

  def trending do
    query = """
    query {
      Page(page: 1, perPage: 20) {
        media(type: ANIME, sort: TRENDING_DESC, isAdult: false) {
          id
          title {
            romaji
            english
          }
          coverImage {
            large
          }
          averageScore
          episodes
        }
      }
    }
    """

    case request(query) do
      {:ok, %{"Page" => %{"media" => anime}}} ->
        {:ok, anime}

      error ->
        error
    end
  end

  def search(term) do
    query = """
    query ($search: String) {
      Page(page: 1, perPage: 20) {
        media(
          search: $search
          type: ANIME
          sort: SEARCH_MATCH
          isAdult: false
        ) {
          id
          title {
            romaji
            english
          }
          coverImage {
            large
          }
          averageScore
          episodes
        }
      }
    }
    """

    case request(query, %{search: term}) do
      {:ok, %{"Page" => %{"media" => anime}}} ->
        {:ok, anime}

      error ->
        error
    end
  end

  def anime(id) do
    query = """
    query ($id: Int) {
      Media(id: $id, type: ANIME) {
        id
        title {
          romaji
          english
        }
        coverImage {
          extraLarge
        }
        description
        averageScore
        episodes
        genres
        status
        seasonYear
      }
    }
    """

    request(query, %{id: id})
  end

  defp request(query, variables \\ %{}) do
    case Req.post(
           @endpoint,
           json: %{
             query: query,
             variables: variables
           }
         ) do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok, data}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end
end
