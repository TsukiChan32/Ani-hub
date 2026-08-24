defmodule AnihubWeb.LibraryLive do
  use AnihubWeb, :live_view

  alias Anihub.Anilist
  alias Anihub.Library

  @statuses ["all", "watching", "planning", "completed", "dropped"]

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    entries = Library.list_anime_entries(scope)

    ids = Enum.map(entries, & &1.anilist_id)

    anime =
      case Anilist.anime_by_ids(ids) do
        {:ok, anime} -> anime
        {:error, _reason} -> []
      end

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
      |> Enum.reject(fn item -> is_nil(item.anime) end)

    {:ok,
     socket
     |> assign(:library, library)
     |> assign(:filter, "all")}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket)
      when status in @statuses do
    {:noreply, assign(socket, :filter, status)}
  end

  defp filtered_library(library, "all"), do: library

  defp filtered_library(library, status) do
    Enum.filter(library, fn item ->
      to_string(item.entry.status) == status
    end)
  end

  defp filter_class(filter, current_filter) do
    base =
      "rounded-xl px-4 py-2 text-sm font-medium transition-colors"

    if filter == current_filter do
      case filter do
        "watching" ->
          "#{base} bg-blue-500/15 text-blue-500"

        "planning" ->
          "#{base} bg-violet-500/15 text-violet-500"

        "completed" ->
          "#{base} bg-emerald-500/15 text-emerald-500"

        "dropped" ->
          "#{base} bg-rose-500/15 text-rose-500"

        _ ->
          "#{base} bg-[var(--accent-soft)] text-[var(--accent)]"
      end
    else
      "#{base} text-[var(--text-muted)] hover:bg-[var(--surface-hover)] hover:text-[var(--text)]"
    end
  end

  defp status_badge_class(status) do
    base =
      "rounded-lg px-2.5 py-1 text-xs font-semibold capitalize backdrop-blur-sm"

    case to_string(status) do
      "watching" ->
        "#{base} bg-blue-500/85 text-white"

      "planning" ->
        "#{base} bg-violet-500/85 text-white"

      "completed" ->
        "#{base} bg-emerald-500/85 text-white"

      "dropped" ->
        "#{base} bg-rose-500/85 text-white"

      _ ->
        "#{base} bg-[var(--surface)] text-[var(--text)]"
    end
  end
end
