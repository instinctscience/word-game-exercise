defmodule Instinct.Repo do
  use Ecto.Repo,
    otp_app: :instinct,
    adapter: Ecto.Adapters.Postgres
end
