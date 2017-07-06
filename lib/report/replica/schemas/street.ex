defmodule Report.Replica.Street do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "streets" do
    field :postal_code, :string
    field :street_name, :string
    field :numbers, {:array, :string}
    field :street_type, :string

    timestamps()

    has_many :aliases, Report.Replica.StreetAliases

    belongs_to :region, Report.Replica.Region, type: Ecto.UUID
    belongs_to :settlement, Report.Replica.Settlement, type: Ecto.UUID
    belongs_to :district, Report.Replica.District, type: Ecto.UUID
  end
end
