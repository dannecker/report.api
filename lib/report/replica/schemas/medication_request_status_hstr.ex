defmodule Report.Replica.MedicationRequestStatusHistory do
  @moduledoc false
  use Ecto.Schema

  schema "medication_requests_status_hstr" do
    field :status, :string

    belongs_to :medication_request, Report.Replica.MedicationRequest, type: Ecto.UUID

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
