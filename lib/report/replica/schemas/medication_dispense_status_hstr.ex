defmodule Report.Replica.MedicationDispenseStatusHistory do
  @moduledoc false
  use Ecto.Schema

  schema "medication_dispense_status_hstr" do
    field :medication_dispense_id, Ecto.UUID
    field :status, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
