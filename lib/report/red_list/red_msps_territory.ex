defmodule Report.RedMSPTerritory do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "red_msps_territories" do
    field :settlement_id, Ecto.UUID, null: false
    field :street_type, :string
    field :street_name, :string
    field :postal_code, :string, length: 5
    field :buildings, :string, length: 2000
    belongs_to :red_msp, Report.RedMSP, type: Ecto.UUID
    timestamps(type: :utc_datetime)
  end
end
