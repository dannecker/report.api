defmodule Report.Repo.Migrations.CreateMedicationDispenseStatusHstrTable do
  use Ecto.Migration

  def change do
    create table(:medication_dispense_status_hstr) do
      add :medication_dispense_id, :uuid, null: false
      add :status, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
