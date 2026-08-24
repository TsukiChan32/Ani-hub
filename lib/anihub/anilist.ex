defmodule Anihub.Anilist do
  alias Anihub.Anilist.Cache

  @endpoint "https://graphql.anilist.co"

  @trending_ttl :timer.minutes(10)
  @search_ttl :timer.minutes(2)
  @anime_ttl :timer.hours(1)
  @anime_by_ids_ttl :timer.minutes(10)
  @airing_schedule_ttl :timer.minutes(10)

  def trending do
    Cache.fetch(:trending, @trending_ttl, fn ->
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
    end)
  end

  def search(term) do
    normalized_term =
      term
      |> String.trim()
      |> String.downcase()

    Cache.fetch(
      {:search, normalized_term},
      @search_ttl,
      fn ->
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
    )
  end

  def anime_by_ids([]), do: {:ok, []}

  def anime_by_ids(ids) do
    normalized_ids =
      ids
      |> Enum.uniq()
      |> Enum.sort()

    Cache.fetch(
      {:anime_by_ids, normalized_ids},
      @anime_by_ids_ttl,
      fn ->
        query = """
        query ($ids: [Int]) {
          Page(page: 1, perPage: 50) {
            media(id_in: $ids, type: ANIME) {
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

        case request(query, %{ids: normalized_ids}) do
          {:ok, %{"Page" => %{"media" => anime}}} ->
            {:ok, anime}

          error ->
            error
        end
      end
    )
  end

  def airing_schedule(from_timestamp, to_timestamp) do
    Cache.fetch(
      {:airing_schedule, from_timestamp, to_timestamp},
      @airing_schedule_ttl,
      fn ->
        query = """
        query ($from: Int, $to: Int) {
          Page(page: 1, perPage: 50) {
            airingSchedules(
              airingAt_greater: $from
              airingAt_lesser: $to
              sort: TIME
            ) {
              id
              episode
              airingAt

              media {
                id
                title {
                  romaji
                  english
                }
                coverImage {
                  large
                }
                episodes
              }
            }
          }
        }
        """

        case request(query, %{
               from: from_timestamp,
               to: to_timestamp
             }) do
          {:ok, %{"Page" => %{"airingSchedules" => schedules}}} ->
            {:ok, schedules}

          error ->
            error
        end
      end
    )
  end

  def anime(id) do
    Cache.fetch(
      {:anime, id},
      @anime_ttl,
      fn ->
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
    )
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
