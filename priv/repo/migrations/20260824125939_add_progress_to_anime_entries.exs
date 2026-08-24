defmodule Anihub.Repo.Migrations.AddProgressToAnimeEntries do
  use Ecto.Migration

  def change do
    alter table(:anime_entries) do
      add :progress, :integer, null: false, default: 0
    end
  end
end
