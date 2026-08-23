defmodule Anihub.Repo do
  use Ecto.Repo,
    otp_app: :anihub,
    adapter: Ecto.Adapters.Postgres
end
