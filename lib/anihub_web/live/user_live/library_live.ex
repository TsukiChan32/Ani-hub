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
      |> Enum.reject(fn item ->
        is_nil(item.anime)
      end)

    {:ok,
     socket
     |> assign(:library, library)
     |> assign(:filter, "all")}
  end

  # --------------------------------------------------
  # FILTER
  # --------------------------------------------------

  @impl true
  def handle_event("filter", %{"status" => status}, socket)
      when status in @statuses do
    {:noreply, assign(socket, :filter, status)}
  end

  # --------------------------------------------------
  # PROGRESS +
  # --------------------------------------------------

  @impl true
  def handle_event("increment_progress", %{"id" => id}, socket) do
    with {:ok, entry_id} <- parse_id(id),
         {:ok, item} <- find_library_item(socket.assigns.library, entry_id) do
      entry = item.entry
      episodes = item.anime["episodes"]
      current_progress = entry.progress || 0

      new_progress =
        if is_integer(episodes) do
          min(current_progress + 1, episodes)
        else
          current_progress + 1
        end

      attrs =
        if is_integer(episodes) and new_progress >= episodes do
          %{
            progress: episodes,
            status: "completed"
          }
        else
          %{
            progress: new_progress
          }
        end

      update_entry(socket, entry, attrs)
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Could not update progress")}
    end
  end

  # --------------------------------------------------
  # PROGRESS -
  # --------------------------------------------------

  @impl true
  def handle_event("decrement_progress", %{"id" => id}, socket) do
    with {:ok, entry_id} <- parse_id(id),
         {:ok, item} <- find_library_item(socket.assigns.library, entry_id) do
      entry = item.entry
      current_progress = entry.progress || 0
      new_progress = max(current_progress - 1, 0)

      attrs =
        if to_string(entry.status) == "completed" do
          %{
            progress: new_progress,
            status: "watching"
          }
        else
          %{
            progress: new_progress
          }
        end

      update_entry(socket, entry, attrs)
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Could not update progress")}
    end
  end

  # --------------------------------------------------
  # SCORE
  # --------------------------------------------------

  @impl true
  def handle_event(
        "set_score",
        %{"entry_id" => id, "score" => ""},
        socket
      ) do
    with {:ok, entry_id} <- parse_id(id),
         {:ok, item} <- find_library_item(socket.assigns.library, entry_id) do
      update_entry(socket, item.entry, %{score: nil})
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Could not update score")}
    end
  end

  @impl true
  def handle_event(
        "set_score",
        %{"entry_id" => id, "score" => score},
        socket
      ) do
    with {:ok, entry_id} <- parse_id(id),
         {:ok, parsed_score} <- parse_score(score),
         {:ok, item} <- find_library_item(socket.assigns.library, entry_id) do
      update_entry(socket, item.entry, %{score: parsed_score})
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Could not update score")}
    end
  end

  # --------------------------------------------------
  # STATUS
  # --------------------------------------------------

  @impl true
  def handle_event(
        "set_status",
        %{"id" => id, "status" => status},
        socket
      )
      when status in ["watching", "planning", "completed", "dropped"] do
    with {:ok, entry_id} <- parse_id(id),
         {:ok, item} <- find_library_item(socket.assigns.library, entry_id) do
      entry = item.entry
      episodes = item.anime["episodes"]

      attrs =
        if status == "completed" and is_integer(episodes) do
          %{
            status: status,
            progress: episodes
          }
        else
          %{
            status: status
          }
        end

      update_entry(socket, entry, attrs)
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Could not update status")}
    end
  end

  # --------------------------------------------------
  # DB + SOCKET UPDATE
  # --------------------------------------------------

  defp update_entry(socket, entry, attrs) do
    scope = socket.assigns.current_scope

    case Library.update_anime_entry(scope, entry, attrs) do
      {:ok, updated_entry} ->
        library =
          Enum.map(socket.assigns.library, fn item ->
            if item.entry.id == updated_entry.id do
              %{item | entry: updated_entry}
            else
              item
            end
          end)

        {:noreply, assign(socket, :library, library)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update library entry")}
    end
  end

  # --------------------------------------------------
  # LOOKUPS
  # --------------------------------------------------

  defp find_library_item(library, entry_id) do
    case Enum.find(library, fn item ->
           item.entry.id == entry_id
         end) do
      nil ->
        {:error, :not_found}

      item ->
        {:ok, item}
    end
  end

  defp parse_id(id) when is_integer(id), do: {:ok, id}

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {id, ""} -> {:ok, id}
      _ -> {:error, :invalid_id}
    end
  end

  defp parse_id(_), do: {:error, :invalid_id}

  defp parse_score(score)
       when is_integer(score) and
              score >= 1 and
              score <= 10 do
    {:ok, score}
  end

  defp parse_score(score) when is_binary(score) do
    case Integer.parse(score) do
      {score, ""} when score >= 1 and score <= 10 ->
        {:ok, score}

      _ ->
        {:error, :invalid_score}
    end
  end

  defp parse_score(_), do: {:error, :invalid_score}

  # --------------------------------------------------
  # FILTERING
  # --------------------------------------------------

  defp filtered_library(library, "all"), do: library

  defp filtered_library(library, status) do
    Enum.filter(library, fn item ->
      to_string(item.entry.status) == status
    end)
  end

  # --------------------------------------------------
  # FILTER STYLING
  # --------------------------------------------------

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

  # --------------------------------------------------
  # STATUS BADGE
  # --------------------------------------------------

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
