defmodule Report.Replica.Settlement do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "settlements" do
    field :type, :string
    field :name, :string
    field :mountain_group, :boolean
    field :koatuu, :string

    timestamps()

    belongs_to :region, Report.Replica.Region, type: Ecto.UUID
    belongs_to :district, Report.Replica.District, type: Ecto.UUID
    belongs_to :parent_settlement, Report.Replica.Settlement, type: Ecto.UUID
  end
end
