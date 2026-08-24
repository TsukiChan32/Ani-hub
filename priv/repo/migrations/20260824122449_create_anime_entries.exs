defmodule Anihub.Repo.Migrations.CreateAnimeEntries do
  use Ecto.Migration

  def change do
    create table(:anime_entries) do
      add :anilist_id, :integer, null: false
      add :status, :string, null: false

      add :user_id,
          references(:users, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create index(:anime_entries, [:user_id])

    create unique_index(
             :anime_entries,
             [:user_id, :anilist_id]
           )
  end
end
