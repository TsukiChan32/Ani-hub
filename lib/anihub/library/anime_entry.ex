defmodule Anihub.Library.AnimeEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Anihub.Accounts.Scope

  schema "anime_entries" do
    field :anilist_id, :integer

    field :status, Ecto.Enum, values: [:planning, :watching, :completed, :dropped]

    field :progress, :integer, default: 0
    field :score, :integer

    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(anime_entry, attrs, %Scope{} = scope) do
    anime_entry
    |> cast(attrs, [
      :anilist_id,
      :status,
      :progress,
      :score
    ])
    |> validate_required([
      :anilist_id,
      :status
    ])
    |> validate_number(
      :progress,
      greater_than_or_equal_to: 0
    )
    |> validate_number(
      :score,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 10
    )
    |> put_change(:user_id, scope.user.id)
  end
end
