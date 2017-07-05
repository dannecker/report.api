defmodule Report.Replica.Region do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "regions" do
    field :name, :string
    field :koatuu, :string
    timestamps()

    has_many :districts, Report.Replica.District
  end
end
