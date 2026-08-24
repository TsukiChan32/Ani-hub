defmodule Anihub.LibraryTest do
  use Anihub.DataCase

  alias Anihub.Library

  describe "anime_entries" do
    alias Anihub.Library.AnimeEntry

    import Anihub.AccountsFixtures, only: [user_scope_fixture: 0]
    import Anihub.LibraryFixtures

    @invalid_attrs %{status: nil, anilist_id: nil}

    test "list_anime_entries/1 returns all scoped anime_entries" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      anime_entry = anime_entry_fixture(scope)
      other_anime_entry = anime_entry_fixture(other_scope)
      assert Library.list_anime_entries(scope) == [anime_entry]
      assert Library.list_anime_entries(other_scope) == [other_anime_entry]
    end

    test "get_anime_entry!/2 returns the anime_entry with given id" do
      scope = user_scope_fixture()
      anime_entry = anime_entry_fixture(scope)
      other_scope = user_scope_fixture()
      assert Library.get_anime_entry!(scope, anime_entry.id) == anime_entry

      assert_raise Ecto.NoResultsError, fn ->
        Library.get_anime_entry!(other_scope, anime_entry.id)
      end
    end

    test "create_anime_entry/2 with valid data creates a anime_entry" do
      valid_attrs = %{status: "some status", anilist_id: 42}
      scope = user_scope_fixture()

      assert {:ok, %AnimeEntry{} = anime_entry} = Library.create_anime_entry(scope, valid_attrs)
      assert anime_entry.status == "some status"
      assert anime_entry.anilist_id == 42
      assert anime_entry.user_id == scope.user.id
    end

    test "create_anime_entry/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.create_anime_entry(scope, @invalid_attrs)
    end

    test "update_anime_entry/3 with valid data updates the anime_entry" do
      scope = user_scope_fixture()
      anime_entry = anime_entry_fixture(scope)
      update_attrs = %{status: "some updated status", anilist_id: 43}

      assert {:ok, %AnimeEntry{} = anime_entry} =
               Library.update_anime_entry(scope, anime_entry, update_attrs)

      assert anime_entry.status == "some updated status"
      assert anime_entry.anilist_id == 43
    end

    test "update_anime_entry/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      anime_entry = anime_entry_fixture(scope)

      assert_raise MatchError, fn ->
        Library.update_anime_entry(other_scope, anime_entry, %{})
      end
    end

    test "update_anime_entry/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      anime_entry = anime_entry_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Library.update_anime_entry(scope, anime_entry, @invalid_attrs)

      assert anime_entry == Library.get_anime_entry!(scope, anime_entry.id)
    end

    test "delete_anime_entry/2 deletes the anime_entry" do
      scope = user_scope_fixture()
      anime_entry = anime_entry_fixture(scope)
      assert {:ok, %AnimeEntry{}} = Library.delete_anime_entry(scope, anime_entry)
      assert_raise Ecto.NoResultsError, fn -> Library.get_anime_entry!(scope, anime_entry.id) end
    end

    test "delete_anime_entry/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      anime_entry = anime_entry_fixture(scope)
      assert_raise MatchError, fn -> Library.delete_anime_entry(other_scope, anime_entry) end
    end

    test "change_anime_entry/2 returns a anime_entry changeset" do
      scope = user_scope_fixture()
      anime_entry = anime_entry_fixture(scope)
      assert %Ecto.Changeset{} = Library.change_anime_entry(scope, anime_entry)
    end
  end
end
