defmodule LvMaybeBug.Repo do
  use Ecto.Repo,
    otp_app: :lv_maybe_bug,
    adapter: Ecto.Adapters.Postgres
end
