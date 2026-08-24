defmodule AnihubWeb.SearchLive do
  use AnihubWeb, :live_view

  alias Anihub.Anilist

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:results, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query =
      params
      |> Map.get("q", "")
      |> String.trim()

    {:noreply, search(socket, query)}
  end

  defp search(socket, query) when byte_size(query) < 2 do
    socket
    |> assign(:query, query)
    |> assign(:results, [])
  end

  defp search(socket, query) do
    results =
      case Anilist.search(query) do
        {:ok, results} ->
          results

        {:error, _reason} ->
          []
      end

    socket
    |> assign(:query, query)
    |> assign(:results, results)
  end
end
