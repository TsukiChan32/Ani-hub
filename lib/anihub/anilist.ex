defmodule Anihub.Anilist do
  def anime(id) do
    query = """
       query ($id: Int) {
        Media(id: $id, type: ANIME) {
        id 
        title {
        romaji
        english
        }
      }
    }
    """

    case Req.post(
           "https://graphql.anilist.co",
           json: %{
             query: query,
             variables: %{id: id}
           }
         ) do
      {:ok, %{status: 200, body: %{"data" => %{"Media" => anime}}}} ->
        {:ok, anime}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end
end
