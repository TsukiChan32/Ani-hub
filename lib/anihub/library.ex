defmodule Anihub.Library do
  @moduledoc """
  The Library context.
  """

  import Ecto.Query, warn: false
  alias Anihub.Repo

  alias Anihub.Library.AnimeEntry
  alias Anihub.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any anime_entry changes.

  The broadcasted messages match the pattern:

    * {:created, %AnimeEntry{}}
    * {:updated, %AnimeEntry{}}
    * {:deleted, %AnimeEntry{}}

  """
  def subscribe_anime_entries(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Anihub.PubSub, "user:#{key}:anime_entries")
  end

  defp broadcast_anime_entry(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Anihub.PubSub, "user:#{key}:anime_entries", message)
  end

  @doc """
  Returns the list of anime_entries.

  ## Examples

      iex> list_anime_entries(scope)
      [%AnimeEntry{}, ...]

  """
  def list_anime_entries(%Scope{} = scope) do
    Repo.all_by(AnimeEntry, user_id: scope.user.id)
  end

  @doc """
  Gets a single anime_entry.

  Raises `Ecto.NoResultsError` if the Anime entry does not exist.

  ## Examples

      iex> get_anime_entry!(scope, 123)
      %AnimeEntry{}

      iex> get_anime_entry!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_anime_entry!(%Scope{} = scope, id) do
    Repo.get_by!(AnimeEntry, id: id, user_id: scope.user.id)
  end

  def get_anime_entry_by_anilist_id(%Scope{} = scope, anilist_id) do
    Repo.get_by(AnimeEntry,
      user_id: scope.user.id,
      anilist_id: anilist_id
    )
  end

  @doc """
  Creates a anime_entry.

  ## Examples

      iex> create_anime_entry(scope, %{field: value})
      {:ok, %AnimeEntry{}}

      iex> create_anime_entry(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_anime_entry(%Scope{} = scope, attrs) do
    with {:ok, anime_entry = %AnimeEntry{}} <-
           %AnimeEntry{}
           |> AnimeEntry.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_anime_entry(scope, {:created, anime_entry})
      {:ok, anime_entry}
    end
  end

  @doc """
  Updates a anime_entry.

  ## Examples

      iex> update_anime_entry(scope, anime_entry, %{field: new_value})
      {:ok, %AnimeEntry{}}

      iex> update_anime_entry(scope, anime_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_anime_entry(%Scope{} = scope, %AnimeEntry{} = anime_entry, attrs) do
    true = anime_entry.user_id == scope.user.id

    with {:ok, anime_entry = %AnimeEntry{}} <-
           anime_entry
           |> AnimeEntry.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_anime_entry(scope, {:updated, anime_entry})
      {:ok, anime_entry}
    end
  end

  @doc """
  Deletes a anime_entry.

  ## Examples

      iex> delete_anime_entry(scope, anime_entry)
      {:ok, %AnimeEntry{}}

      iex> delete_anime_entry(scope, anime_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_anime_entry(%Scope{} = scope, %AnimeEntry{} = anime_entry) do
    true = anime_entry.user_id == scope.user.id

    with {:ok, anime_entry = %AnimeEntry{}} <-
           Repo.delete(anime_entry) do
      broadcast_anime_entry(scope, {:deleted, anime_entry})
      {:ok, anime_entry}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking anime_entry changes.

  ## Examples

      iex> change_anime_entry(scope, anime_entry)
      %Ecto.Changeset{data: %AnimeEntry{}}

  """
  def change_anime_entry(%Scope{} = scope, %AnimeEntry{} = anime_entry, attrs \\ %{}) do
    true = anime_entry.user_id == scope.user.id

    AnimeEntry.changeset(anime_entry, attrs, scope)
  end
end
