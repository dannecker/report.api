defmodule Report.Billing do
  @moduledoc """
    Ecto Schema for Billing table
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "billings" do
    field :billing_date, Timex.Ecto.Date, null: false, default: Timex.today()
    belongs_to :declaration, Report.Replica.Declaration, type: Ecto.UUID
    belongs_to :legal_entity, Report.Replica.LegalEnity, type: Ecto.UUID
    field :mountain_group, :string
    field :age_group, :string
    timestamps(type: :utc_datetime)
  end
end
