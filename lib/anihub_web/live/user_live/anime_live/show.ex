defmodule AnihubWeb.AnimeLive.Show do
  use AnihubWeb, :live_view

  alias Anihub.Library

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    id = String.to_integer(id)

    case Anihub.Anilist.anime(id) do
      {:ok, %{"Media" => anime}} ->
        library_entry =
          case socket.assigns.current_scope do
            nil ->
              nil

            scope ->
              Library.get_anime_entry_by_anilist_id(scope, id)
          end

        {:ok,
         socket
         |> assign(:anime, anime)
         |> assign(:library_entry, library_entry)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Anime not found")
         |> push_navigate(to: ~p"/")}

      {:error, {:http_error, 429, _response}} ->
        {:ok,
         socket
         |> put_flash(
           :error,
           "AniList is temporarily rate limiting requests. Try again in a moment."
         )
         |> push_navigate(to: ~p"/")}

      {:error, _reason} ->
        {:ok,
         socket
         |> put_flash(
           :error,
           "Could not load this anime right now. Please try again."
         )
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("add_to_library", %{"status" => status}, socket) do
    scope = socket.assigns.current_scope
    anime = socket.assigns.anime

    attrs = %{
      anilist_id: anime["id"],
      status: status,
      progress: initial_progress(status, anime["episodes"])
    }

    case Library.create_anime_entry(scope, attrs) do
      {:ok, entry} ->
        {:noreply, assign(socket, :library_entry, entry)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not add anime to library")}
    end
  end

  @impl true
  def handle_event("set_status", %{"status" => status}, socket) do
    scope = socket.assigns.current_scope
    entry = socket.assigns.library_entry
    anime = socket.assigns.anime

    attrs =
      case status do
        "completed" ->
          %{
            status: status,
            progress: anime["episodes"] || entry.progress
          }

        _ ->
          %{status: status}
      end

    case Library.update_anime_entry(scope, entry, attrs) do
      {:ok, updated_entry} ->
        {:noreply, assign(socket, :library_entry, updated_entry)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update status")}
    end
  end

  @impl true
  def handle_event("remove_from_library", _params, socket) do
    scope = socket.assigns.current_scope
    entry = socket.assigns.library_entry

    case Library.delete_anime_entry(scope, entry) do
      {:ok, _entry} ->
        {:noreply, assign(socket, :library_entry, nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not remove anime from library")}
    end
  end

  @impl true
  def handle_event("increment_progress", _params, socket) do
    entry = socket.assigns.library_entry
    anime = socket.assigns.anime
    scope = socket.assigns.current_scope

    current_progress = entry.progress || 0
    max_episodes = anime["episodes"]

    new_progress =
      if is_integer(max_episodes) do
        min(current_progress + 1, max_episodes)
      else
        current_progress + 1
      end

    update_progress(socket, scope, entry, new_progress)
  end

  @impl true
  def handle_event("decrement_progress", _params, socket) do
    entry = socket.assigns.library_entry
    scope = socket.assigns.current_scope

    current_progress = entry.progress || 0
    new_progress = max(current_progress - 1, 0)

    update_progress(socket, scope, entry, new_progress)
  end

  defp update_progress(socket, scope, entry, progress) do
    episodes = socket.assigns.anime["episodes"]

    attrs =
      cond do
        is_integer(episodes) and progress >= episodes ->
          %{
            progress: episodes,
            status: "completed"
          }

        to_string(entry.status) == "completed" ->
          %{
            progress: progress,
            status: "watching"
          }

        true ->
          %{
            progress: progress
          }
      end

    case Library.update_anime_entry(scope, entry, attrs) do
      {:ok, updated_entry} ->
        {:noreply, assign(socket, :library_entry, updated_entry)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update progress")}
    end
  end

  defp initial_progress("completed", episodes)
       when is_integer(episodes),
       do: episodes

  defp initial_progress(_, _), do: 0

  defp status_button_class(status, current_status) do
    base = "border px-3 py-2 text-sm font-semibold"

    active? =
      to_string(status) == to_string(current_status)

    case {to_string(status), active?} do
      {"watching", true} ->
        "#{base} border-blue-700 bg-blue-700 text-white"

      {"planning", true} ->
        "#{base} border-violet-700 bg-violet-700 text-white"

      {"completed", true} ->
        "#{base} border-emerald-700 bg-emerald-700 text-white"

      {"dropped", true} ->
        "#{base} border-rose-700 bg-rose-700 text-white"

      {_, false} ->
        "#{base} border-[var(--border)] bg-[var(--surface)] text-[var(--text)] hover:bg-[var(--surface-hover)]"
    end
  end

  defp anime_status_label("RELEASING"), do: "Currently airing"
  defp anime_status_label("FINISHED"), do: "Finished airing"
  defp anime_status_label("NOT_YET_RELEASED"), do: "Not yet released"
  defp anime_status_label("CANCELLED"), do: "Cancelled"
  defp anime_status_label("HIATUS"), do: "On hiatus"

  defp anime_status_label(status) when is_binary(status),
    do: String.capitalize(status)

  defp anime_status_label(_), do: nil

  defp season_label(nil), do: nil

  defp season_label(season) do
    season
    |> String.downcase()
    |> String.capitalize()
  end

  defp format_label(nil), do: nil
  defp format_label("TV"), do: "TV"
  defp format_label("TV_SHORT"), do: "TV Short"
  defp format_label("MOVIE"), do: "Movie"
  defp format_label("SPECIAL"), do: "Special"
  defp format_label("OVA"), do: "OVA"
  defp format_label("ONA"), do: "ONA"
  defp format_label("MUSIC"), do: "Music"

  defp format_label(format) do
    format
    |> String.replace("_", " ")
    |> String.downcase()
    |> String.capitalize()
  end

  defp main_studio(%{"nodes" => [%{"name" => name} | _]}), do: name
  defp main_studio(_), do: nil

  defp related_anime(anime) do
    anime
    |> get_in(["relations", "edges"])
    |> List.wrap()
    |> Enum.filter(fn edge ->
      get_in(edge, ["node", "type"]) == "ANIME"
    end)
    |> Enum.sort_by(fn edge ->
      relation_priority(edge["relationType"])
    end)
    |> Enum.take(6)
  end

  defp relation_priority("PREQUEL"), do: 1
  defp relation_priority("SEQUEL"), do: 2
  defp relation_priority("PARENT"), do: 3
  defp relation_priority("SIDE_STORY"), do: 4
  defp relation_priority("SPIN_OFF"), do: 5
  defp relation_priority("ALTERNATIVE"), do: 6
  defp relation_priority("CHARACTER"), do: 7
  defp relation_priority(_), do: 8

  defp relation_label(nil), do: nil

  defp relation_label(type) do
    type
    |> String.replace("_", " ")
    |> String.downcase()
    |> String.capitalize()
  end

  defp source_label(nil), do: nil

  defp source_label(source) do
    source
    |> String.replace("_", " ")
    |> String.downcase()
    |> String.capitalize()
  end

  defp country_label("JP"), do: "Japan"
  defp country_label("KR"), do: "South Korea"
  defp country_label("CN"), do: "China"
  defp country_label("TW"), do: "Taiwan"
  defp country_label(country), do: country

  defp anime_date(nil), do: nil
  defp anime_date(%{"year" => nil}), do: nil

  defp anime_date(%{"year" => year, "month" => nil}) do
    Integer.to_string(year)
  end

  defp anime_date(%{"year" => year, "month" => month, "day" => nil}) do
    "#{month}/#{year}"
  end

  defp anime_date(%{"year" => year, "month" => month, "day" => day}) do
    "#{day}/#{month}/#{year}"
  end
end
