defmodule Report.Billing do
  @moduledoc """
    Ecto Schema for Billing table
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "billings" do
    field :billing_date, Timex.Ecto.Date, null: false, default: Timex.today()
    belongs_to :declaration, Report.Replica.Declaration, type: Ecto.UUID
    belongs_to :legal_entity, Report.Replica.LegalEntity, type: Ecto.UUID
    belongs_to :division, Report.Replica.Division, type: Ecto.UUID
    belongs_to :red_msp, Report.RedMSP, type: Ecto.UUID
    field :mountain_group, :boolean, null: false
    field :person_age, :integer, null: false
    field :compensation_group, :string, null: false
    field :decision_id, :string, null: false
    field :is_valid, :boolean, null: false
    timestamps(type: :utc_datetime)
  end
end
