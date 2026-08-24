defmodule AnihubWeb.SearchLive do
  use AnihubWeb, :live_view

  alias Anihub.Anilist

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:results, [])}
  end

  def handle_event("search", %{"q" => query}, socket) do
    query = String.trim(query)

    cond do
      String.length(query) < 2 ->
        {:noreply,
         socket
         |> assign(:query, query)
         |> assign(:results, [])}

      true ->
        case Anilist.search(query) do
          {:ok, results} ->
            {:noreply,
             socket
             |> assign(:query, query)
             |> assign(:results, Enum.take(results, 6))}

          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:query, query)
             |> assign(:results, [])}
        end
    end
  end
end
