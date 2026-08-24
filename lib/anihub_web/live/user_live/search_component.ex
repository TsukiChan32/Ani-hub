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
        <div class="relative">
          <div class="
            pointer-events-none
            absolute inset-y-0 left-0
            flex items-center
            pl-4
            text-[var(--text-muted)]
          ">
            <.icon name="hero-magnifying-glass" class="size-5" />
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
              w-full
              rounded-2xl
              border border-[var(--border)]
              bg-[var(--surface)]
              py-3.5
              pr-4
              pl-12
              text-[var(--text)]
              placeholder:text-[var(--text-muted)]
              outline-none
              transition
              focus:border-[var(--accent)]
              focus:ring-2
              focus:ring-[var(--accent-soft)]
            "
          />
        </div>
      </form>

      <%!-- Results dropdown --%>
      <%= if @query != "" and @results != [] do %>
        <div class="
          absolute
          left-0 right-0 top-full
          z-50
          mt-2
          overflow-hidden
          rounded-2xl
          border border-[var(--border)]
          bg-[var(--surface)]
          shadow-lg
        ">
          <div class="p-2">
            <%= for anime <- @results do %>
              <.link
                navigate={~p"/anime/#{anime["id"]}"}
                class="
                  group
                  flex items-center gap-3
                  rounded-xl
                  p-2
                  transition-colors
                  hover:bg-[var(--surface-hover)]
                "
              >
                <img
                  src={anime["coverImage"]["large"]}
                  alt={anime["title"]["english"] || anime["title"]["romaji"]}
                  class="
                    h-16 w-11
                    shrink-0
                    rounded-lg
                    object-cover
                  "
                />

                <div class="min-w-0 flex-1">
                  <div class="
                    truncate
                    font-medium
                    text-[var(--text)]
                    transition-colors
                    group-hover:text-[var(--accent)]
                  ">
                    {anime["title"]["english"] || anime["title"]["romaji"]}
                  </div>

                  <div class="
                    mt-1
                    flex items-center gap-2
                    text-sm
                    text-[var(--text-muted)]
                  ">
                    <%= if anime["averageScore"] do %>
                      <span>
                        {anime["averageScore"]}%
                      </span>
                    <% end %>

                    <%= if anime["seasonYear"] do %>
                      <span class="text-[var(--border)]">
                        •
                      </span>

                      <span>
                        {anime["seasonYear"]}
                      </span>
                    <% end %>
                  </div>
                </div>

                <.icon
                  name="hero-chevron-right"
                  class="
                    size-4
                    shrink-0
                    text-[var(--text-muted)]
                    opacity-0
                    transition
                    group-hover:translate-x-0.5
                    group-hover:opacity-100
                  "
                />
              </.link>
            <% end %>
          </div>

          <%!-- View all --%>
          <a
            href={"/search?q=#{URI.encode_www_form(@query)}"}
            class="
              flex items-center
              justify-center gap-1
              border-t border-[var(--border)]
              px-4 py-3
              text-sm font-medium
              text-[var(--accent)]
              transition-colors
              hover:bg-[var(--surface-hover)]
            "
          >
            View all results
            <.icon
              name="hero-arrow-right"
              class="size-4"
            />
          </a>
        </div>
      <% end %>
    </div>
    """
  end
end
