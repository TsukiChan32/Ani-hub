defmodule AnihubWeb.CalendarLive do
  use AnihubWeb, :live_view

  alias Anihub.Anilist
  alias Anihub.Library

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    week_start = beginning_of_week(today)

    watching_ids =
      case socket.assigns.current_scope do
        nil ->
          MapSet.new()

        scope ->
          scope
          |> Library.list_anime_entries()
          |> Enum.filter(fn entry ->
            to_string(entry.status) == "watching"
          end)
          |> Enum.map(& &1.anilist_id)
          |> MapSet.new()
      end

    {:ok,
     socket
     |> assign(:today, today)
     |> assign(:watching_ids, watching_ids)
     |> load_week(week_start)}
  end

  @impl true
  def handle_event("previous_week", _params, socket) do
    week_start = Date.add(socket.assigns.week_start, -7)

    {:noreply, load_week(socket, week_start)}
  end

  @impl true
  def handle_event("next_week", _params, socket) do
    week_start = Date.add(socket.assigns.week_start, 7)

    {:noreply, load_week(socket, week_start)}
  end

  @impl true
  def handle_event("this_week", _params, socket) do
    week_start =
      socket.assigns.today
      |> beginning_of_week()

    {:noreply, load_week(socket, week_start)}
  end

  defp load_week(socket, week_start) do
    week_end = Date.add(week_start, 7)

    # We deliberately fetch a little before and after the selected week.
    # The browser decides which local day each airing belongs to.
    from_timestamp =
      week_start
      |> Date.add(-1)
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")
      |> DateTime.to_unix()

    to_timestamp =
      week_end
      |> Date.add(1)
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")
      |> DateTime.to_unix()

    schedules =
      case Anilist.airing_schedule(from_timestamp, to_timestamp) do
        {:ok, schedules} ->
          schedules

        {:error, _reason} ->
          []
      end

    days =
      Enum.map(0..6, fn offset ->
        Date.add(week_start, offset)
      end)

    socket
    |> assign(:week_start, week_start)
    |> assign(:week_end, Date.add(week_start, 6))
    |> assign(:days, days)
    |> assign(:schedules, schedules)
  end

  defp beginning_of_week(date) do
    Date.add(date, -(Date.day_of_week(date) - 1))
  end

  defp day_name(date) do
    case Date.day_of_week(date) do
      1 -> "Monday"
      2 -> "Tuesday"
      3 -> "Wednesday"
      4 -> "Thursday"
      5 -> "Friday"
      6 -> "Saturday"
      7 -> "Sunday"
    end
  end

  defp library_status(watching_ids, media_id) do
    if MapSet.member?(watching_ids, media_id) do
      "watching"
    else
      "none"
    end
  end
end
