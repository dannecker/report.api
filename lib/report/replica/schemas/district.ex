defmodule Report.Replica.District do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "districts" do
    field :name, :string
    field :koatuu, :string

    timestamps()

    belongs_to :region, Report.Replica.Region, type: Ecto.UUID

    has_many :settlements, Report.Replica.Settlement
  end
end
