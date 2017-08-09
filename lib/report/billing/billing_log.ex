defmodule Report.BillingLog do
  @moduledoc """
    Ecto Schema for Billing table
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "billing_logs" do
    field :billing_date, Timex.Ecto.Date, null: false, default: Timex.today()
    field :declaration_id, Ecto.UUID, null: true
    field :legal_entity_id, Ecto.UUID, null: true
    field :person_id, Ecto.UUID, null: true
    field :division_id, Ecto.UUID, null: true
    field :message, :string, null: false
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
