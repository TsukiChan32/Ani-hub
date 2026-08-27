defmodule Anihub.Anilist do
  alias Anihub.Anilist.Cache

  @endpoint "https://graphql.anilist.co"

  @trending_ttl :timer.minutes(10)
  @search_ttl :timer.minutes(2)
  @anime_ttl :timer.hours(1)
  @anime_by_ids_ttl :timer.minutes(10)
  @airing_schedule_ttl :timer.minutes(10)
  @discover_ttl :timer.minutes(10)
  @genres_ttl :timer.hours(24)

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
            bannerImage
            description
            averageScore
            episodes
            seasonYear
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

  # --------------------------------------------------
  # DISCOVER
  # --------------------------------------------------

  def discover(params \\ %{}) do
    params = normalize_discover_params(params)

    Cache.fetch(
      {:discover, params},
      @discover_ttl,
      fn ->
        discover_request(params)
      end
    )
  end

  defp discover_request(params) do
    query = """
    query (
      $page: Int
      $season: MediaSeason
      $year: Int
      $genre: String
      $sort: [MediaSort]
    ) {
      Page(page: $page, perPage: 30) {
        pageInfo {
          currentPage
          hasNextPage
          lastPage
          total
        }

        media(
          type: ANIME
          season: $season
          seasonYear: $year
          genre: $genre
          sort: $sort
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
          popularity
          episodes
          format
          status
          season
          seasonYear
          genres
        }
      }
    }
    """

    variables = %{
      page: params.page,
      season: params.season,
      year: params.year,
      genre: params.genre,
      sort: [params.sort]
    }

    case request(query, variables) do
      {:ok,
       %{
         "Page" => %{
           "media" => anime,
           "pageInfo" => page_info
         }
       }} ->
        {:ok,
         %{
           anime: anime,
           page_info: page_info
         }}

      error ->
        error
    end
  end

  # --------------------------------------------------
  # GENRES
  # --------------------------------------------------

  def genres do
    Cache.fetch(
      :genres,
      @genres_ttl,
      fn ->
        query = """
        query {
          GenreCollection
        }
        """

        case request(query) do
          {:ok, %{"GenreCollection" => genres}} ->
            {:ok, genres}

          error ->
            error
        end
      end
    )
  end

  # --------------------------------------------------
  # DISCOVER PARAMS
  # --------------------------------------------------

  defp normalize_discover_params(params) do
    %{
      page:
        params
        |> get_param(:page, 1)
        |> normalize_page(),
      season:
        params
        |> get_param(:season)
        |> normalize_season(),
      year:
        params
        |> get_param(:year)
        |> normalize_year(),
      genre:
        params
        |> get_param(:genre)
        |> normalize_genre(),
      sort:
        params
        |> get_param(:sort, "trending")
        |> normalize_discover_sort()
    }
  end

  defp get_param(params, key, default \\ nil) do
    Map.get(params, key) ||
      Map.get(params, Atom.to_string(key)) ||
      default
  end

  defp normalize_page(page) when is_integer(page) and page > 0,
    do: page

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {page, ""} when page > 0 -> page
      _ -> 1
    end
  end

  defp normalize_page(_), do: 1

  defp normalize_year(year) when is_integer(year),
    do: year

  defp normalize_year(year) when is_binary(year) do
    case Integer.parse(year) do
      {year, ""} -> year
      _ -> nil
    end
  end

  defp normalize_year(_), do: nil

  defp normalize_season(season)
       when season in ["WINTER", "SPRING", "SUMMER", "FALL"],
       do: season

  defp normalize_season(season) when is_binary(season) do
    season
    |> String.upcase()
    |> normalize_season()
  end

  defp normalize_season(_), do: nil

  defp normalize_genre(nil), do: nil
  defp normalize_genre(""), do: nil

  defp normalize_genre(genre) when is_binary(genre) do
    String.trim(genre)
  end

  defp normalize_genre(_), do: nil

  defp normalize_discover_sort("trending"),
    do: "TRENDING_DESC"

  defp normalize_discover_sort("popular"),
    do: "POPULARITY_DESC"

  defp normalize_discover_sort("score"),
    do: "SCORE_DESC"

  defp normalize_discover_sort("TRENDING_DESC"),
    do: "TRENDING_DESC"

  defp normalize_discover_sort("POPULARITY_DESC"),
    do: "POPULARITY_DESC"

  defp normalize_discover_sort("SCORE_DESC"),
    do: "SCORE_DESC"

  defp normalize_discover_sort(_),
    do: "TRENDING_DESC"

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
        airing_schedule_page(from_timestamp, to_timestamp, 1)
      end
    )
  end

  defp airing_schedule_page(from_timestamp, to_timestamp, page) do
    query = """
    query ($from: Int, $to: Int, $page: Int) {
      Page(page: $page, perPage: 50) {
        pageInfo {
          hasNextPage
        }

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
           to: to_timestamp,
           page: page
         }) do
      {:ok,
       %{
         "Page" => %{
           "airingSchedules" => schedules,
           "pageInfo" => %{"hasNextPage" => true}
         }
       }} ->
        case airing_schedule_page(from_timestamp, to_timestamp, page + 1) do
          {:ok, next_schedules} ->
            {:ok, schedules ++ next_schedules}

          error ->
            error
        end

      {:ok,
       %{
         "Page" => %{
           "airingSchedules" => schedules
         }
       }} ->
        {:ok, schedules}

      error ->
        error
    end
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
              native
            }

            coverImage {
              extraLarge
            }

            bannerImage
            description
            averageScore
            episodes
            genres
            status
            season
            seasonYear
            format
            duration
            source
            countryOfOrigin

            startDate {
              year
              month
              day
            }

            endDate {
              year
              month
              day
            }

            studios(isMain: true) {
              nodes {
                id
                name
              }
            }

            relations {
              edges {
                relationType

                node {
                  id
                  type

                  title {
                    romaji
                    english
                  }

                  coverImage {
                    large
                  }

                  format
                  seasonYear
                }
              }
            }
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
