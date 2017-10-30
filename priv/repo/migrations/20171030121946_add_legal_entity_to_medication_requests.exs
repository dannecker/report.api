defmodule Report.Repo.Migrations.AddLegalEntityToMedicationRequests do
  use Ecto.Migration

  def change do
    alter table(:medication_requests) do
      add :legal_entity_id, :uuid
    end

    execute "UPDATE medication_requests set legal_entity_id = id;"

    alter table(:medication_requests) do
      modify :legal_entity_id, :uuid, null: false
    end
  end
end
