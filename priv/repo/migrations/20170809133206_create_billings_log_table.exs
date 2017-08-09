defmodule Report.Repo.Migrations.CreateBillingLogsTable do
  use Ecto.Migration

  def change do
    create table(:billing_logs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :billing_date, :date, null: false
      add :legal_entity_id, :uuid, null: true
      add :declaration_id, :uuid, null: true
      add :person_id, :uuid, null: true
      add :division_id, :uuid, null: true
      add :message, :string, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
