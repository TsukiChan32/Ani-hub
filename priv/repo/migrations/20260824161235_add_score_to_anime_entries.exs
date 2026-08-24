defmodule Anihub.Repo.Migrations.AddScoreToAnimeEntries do
  use Ecto.Migration

  def change do
    alter table(:anime_entries) do
      add :score, :integer
    end

    create constraint(
             :anime_entries,
             :anime_entries_score_range,
             check: "score IS NULL OR (score >= 1 AND score <= 10)"
           )
  end
end
