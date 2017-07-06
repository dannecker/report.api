defmodule Report.Replica.StreetsAliases do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "streets_aliases" do
    field :name, :string
    field :street_id, Ecto.UUID
  end
end
