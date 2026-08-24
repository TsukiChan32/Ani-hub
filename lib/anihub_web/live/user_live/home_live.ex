defmodule AnihubWeb.HomeLive do
  use AnihubWeb, :live_view

  alias Anihub.Anilist

  @impl true
  def mount(_params, _session, socket) do
    case Anilist.trending() do
      {:ok, anime} ->
        {:ok, assign(socket, :anime, anime)}

      {:error, _reason} ->
        {:ok,
         socket
         |> assign(:anime, [])
         |> put_flash(:error, "Could not load trending anime")}
    end
  end
end
