defmodule Anihub.Library.AnimeEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "anime_entries" do
    field :anilist_id, :integer

    field :status, Ecto.Enum, values: [:planning, :watching, :completed, :dropped]
    field :progress, :integer, default: 0
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(anime_entry, attrs, user_scope) do
    anime_entry
    |> cast(attrs, [:anilist_id, :status, :progress])
    |> validate_required([:anilist_id, :status])
    |> put_change(:user_id, user_scope.user.id)
    |> unique_constraint([:user_id, :anilist_id])
  end
end
