defmodule AnihubWeb.CalendarLive do
  use AnihubWeb, :live_view

  alias Anihub.Anilist

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()

    week_start =
      Date.add(
        today,
        -(Date.day_of_week(today) - 1)
      )

    week_end = Date.add(week_start, 7)

    from_timestamp =
      week_start
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")
      |> DateTime.to_unix()

    to_timestamp =
      week_end
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")
      |> DateTime.to_unix()

    schedules =
      case Anilist.airing_schedule(
             from_timestamp,
             to_timestamp
           ) do
        {:ok, schedules} ->
          schedules

        {:error, _reason} ->
          []
      end

    days =
      week_start
      |> week_dates()
      |> Enum.map(fn date ->
        %{
          date: date,
          schedules: schedules_for_date(schedules, date)
        }
      end)

    {:ok,
     socket
     |> assign(:week_start, week_start)
     |> assign(:days, days)}
  end

  defp week_dates(start_date) do
    Enum.map(0..6, fn offset ->
      Date.add(start_date, offset)
    end)
  end

  defp schedules_for_date(schedules, date) do
    Enum.filter(schedules, fn schedule ->
      schedule["airingAt"]
      |> DateTime.from_unix!()
      |> DateTime.to_date()
      |> Kernel.==(date)
    end)
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

  defp time_for(schedule) do
    schedule["airingAt"]
    |> DateTime.from_unix!()
    |> Calendar.strftime("%H:%M")
  end
end
