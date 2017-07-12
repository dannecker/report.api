defmodule Report.Billing do
  @moduledoc """
    Ecto Schema for Billing table
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "billings" do
    field :billing_date, :date, null: false
    belongs_to :declaration, Report.Replica.Declaration, type: Ecto.UUID
    belongs_to :legal_enity, Report.Replica.LegalEnity, type: Ecto.UUID
    field :mountain_group, :string
    field :age_group, :string
    timestamps(type: :utc_datetime)
  end
end
