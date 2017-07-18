defmodule Report.Repo.Migrations.CreateDeclarationsStatusHistory do
  use Ecto.Migration

  def change do
    create table(:declarations_status_hstr) do
      add :declaration_id, :uuid, null: false
      add :status, :string, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
