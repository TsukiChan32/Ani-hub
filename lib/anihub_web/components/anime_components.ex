defmodule AnihubWeb.AnimeComponents do
  use Phoenix.Component

  attr :anime, :map, required: true

  def anime_card(assigns) do
    ~H"""
    <a href={"/anime/#{@anime["id"]}"} class="group">
      <img
        src={@anime["coverImage"]["large"]}
        alt={@anime["title"]["english"] || @anime["title"]["romaji"]}
        class="aspect-[2/3] w-full rounded-xl object-cover transition group-hover:scale-[1.02]"
      />

      <h2 class="mt-3 font-semibold">
        {@anime["title"]["english"] || @anime["title"]["romaji"]}
      </h2>

      <div class="mt-1 text-sm text-zinc-400">
        <%= if @anime["averageScore"] do %>
          {@anime["averageScore"]}% ·
        <% end %>

        <%= if @anime["episodes"] do %>
          {@anime["episodes"]} episodes
        <% end %>
      </div>
    </a>
    """
  end
end
