defmodule LvMaybeBug.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :age, :integer
    field :internal_value, :string

    timestamps()
  end

  @doc false
  def component_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :age])
    |> validate_required([:name, :age])
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :age, :internal_value])
    |> validate_required([:name, :age, :internal_value])
  end
end
