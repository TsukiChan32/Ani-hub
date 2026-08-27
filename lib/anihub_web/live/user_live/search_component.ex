defmodule AnihubWeb.SearchComponent do
  use AnihubWeb, :live_component

  alias Anihub.Anilist

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:query, fn -> "" end)
     |> assign_new(:results, fn -> [] end)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    query = String.trim(query)

    results =
      if String.length(query) >= 2 do
        case Anilist.search(query) do
          {:ok, anime} -> Enum.take(anime, 5)
          {:error, _} -> []
        end
      else
        []
      end

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:results, results)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full">
      <%!-- Search input --%>
      <form action="/search" method="get">
        <div class="flex w-full">
          <div class="
            flex
            min-w-0
            flex-1
            items-center
            border border-[var(--border)]
            bg-[var(--surface)]
          ">
            <div class="
              pointer-events-none
              flex
              shrink-0
              items-center
              justify-center
              border-r border-[var(--border)]
              px-3
              text-[var(--text-muted)]
            ">
              <.icon name="hero-magnifying-glass" class="size-4" />
            </div>

            <input
              type="search"
              name="q"
              value={@query}
              placeholder="Search anime..."
              autocomplete="off"
              phx-change="search"
              phx-debounce="300"
              phx-target={@myself}
              class="
                min-w-0
                flex-1
                border-0
                bg-transparent
                px-3 py-2
                text-sm
                text-[var(--text)]
                placeholder:text-[var(--text-muted)]
                outline-none
                focus:ring-0
              "
            />

            <%= if @query != "" do %>
              <a
                href="/"
                class="
                  border-l border-[var(--border)]
                  px-3 py-2
                  text-sm
                  font-bold
                  text-[var(--text-muted)]
                  hover:bg-[var(--surface-hover)]
                  hover:text-[var(--text)]
                "
                aria-label="Clear search"
              >
                ×
              </a>
            <% end %>

            <button
              type="submit"
              class="
                old-button
                border-y-0
                border-r-0
                px-4
                py-2
              "
            >
              Search
            </button>
          </div>
        </div>
      </form>

      <%!-- Results dropdown --%>
      <%= if @query != "" and @results != [] do %>
        <div class="
          absolute
          left-0 right-0 top-full
          z-50
          border-x border-b border-[var(--border)]
          bg-[var(--surface)]
          shadow-md
        ">
          <%!-- Header --%>
          <div class="old-panel-header px-3 py-1.5">
            <div class="flex items-center justify-between gap-3">
              <span class="text-xs font-bold uppercase tracking-wide text-[var(--text)]">
                Search results
              </span>

              <span class="text-xs text-[var(--text-muted)]">
                {length(@results)} shown
              </span>
            </div>
          </div>

          <%!-- Results --%>
          <div class="divide-y divide-[var(--border)]">
            <%= for anime <- @results do %>
              <.link
                navigate={~p"/anime/#{anime["id"]}"}
                class="
                  group
                  grid
                  grid-cols-[44px_minmax(0,1fr)_60px]
                  items-center
                  gap-3
                  px-3 py-2
                  hover:bg-[var(--surface-hover)]
                "
              >
                <img
                  src={anime["coverImage"]["large"]}
                  alt={anime["title"]["english"] || anime["title"]["romaji"]}
                  class="
                    h-14
                    w-10
                    border border-[var(--border)]
                    object-cover
                  "
                />

                <div class="min-w-0">
                  <div class="
                    truncate
                    text-sm
                    font-semibold
                    text-[var(--accent)]
                    group-hover:underline
                  ">
                    {anime["title"]["english"] || anime["title"]["romaji"]}
                  </div>

                  <%= if anime["seasonYear"] do %>
                    <div class="mt-0.5 text-xs text-[var(--text-muted)]">
                      {anime["seasonYear"]}
                    </div>
                  <% end %>
                </div>

                <div class="text-right text-xs">
                  <div class="text-[var(--text-muted)]">
                    Score
                  </div>

                  <div class="mt-0.5 font-semibold text-[var(--text)]">
                    <%= if anime["averageScore"] do %>
                      {anime["averageScore"]}%
                    <% else %>
                      —
                    <% end %>
                  </div>
                </div>
              </.link>
            <% end %>
          </div>

          <%!-- View all --%>
          <div class="
            border-t border-[var(--border)]
            bg-[var(--surface-hover)]
            px-3 py-2
          ">
            <a
              href={"/search?q=#{URI.encode_www_form(@query)}"}
              class="
                text-sm
                font-medium
                text-[var(--accent)]
                hover:underline
              "
            >
              View all results »
            </a>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
