defmodule Report.Repo.Migrations.CreateReportsLog do
  use Ecto.Migration

  def change do
    create table(:report_logs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string
      add :public_url, :string
      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
