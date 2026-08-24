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

    max_episodes = anime["episodes"]

    new_progress =
      if max_episodes do
        min(entry.progress + 1, max_episodes)
      else
        entry.progress + 1
      end

    update_progress(socket, scope, entry, new_progress)
  end

  @impl true
  def handle_event("decrement_progress", _params, socket) do
    entry = socket.assigns.library_entry
    scope = socket.assigns.current_scope

    update_progress(
      socket,
      scope,
      entry,
      max(entry.progress - 1, 0)
    )
  end

  defp update_progress(socket, scope, entry, progress) do
    anime = socket.assigns.anime
    episodes = anime["episodes"]

    attrs =
      if is_integer(episodes) and progress >= episodes do
        %{
          progress: episodes,
          status: "completed"
        }
      else
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
    base =
      "rounded-xl px-4 py-2 text-sm font-medium transition-colors"

    active? =
      to_string(status) == to_string(current_status)

    case {to_string(status), active?} do
      {"watching", true} ->
        "#{base} bg-blue-500/15 text-blue-500"

      {"planning", true} ->
        "#{base} bg-violet-500/15 text-violet-500"

      {"completed", true} ->
        "#{base} bg-emerald-500/15 text-emerald-500"

      {"dropped", true} ->
        "#{base} bg-rose-500/15 text-rose-500"

      {_, false} ->
        "#{base} text-[var(--text-muted)] hover:bg-[var(--surface-hover)] hover:text-[var(--text)]"
    end
  end
end
