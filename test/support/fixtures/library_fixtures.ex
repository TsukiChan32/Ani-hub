defmodule Anihub.LibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Anihub.Library` context.
  """

  @doc """
  Generate a anime_entry.
  """
  def anime_entry_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        anilist_id: 42,
        status: "some status"
      })

    {:ok, anime_entry} = Anihub.Library.create_anime_entry(scope, attrs)
    anime_entry
  end
end
