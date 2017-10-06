defmodule Report.Repo.Migrations.CreateMedicationRequestsStatusHstr do
  use Ecto.Migration

  def change do
    create table(:medication_requests_status_hstr) do
      add :medication_request_id, :uuid, null: false
      add :status, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
