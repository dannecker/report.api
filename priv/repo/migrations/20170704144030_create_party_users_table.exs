defmodule Report.Repo.Migrations.CreatePartyUsersTable do
  use Ecto.Migration

  def change do
    create table(:party_users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, :uuid, null: false
      add :party_id, :uuid

      timestamps(type: :utc_datetime)
    end

    create index(:party_users, [:party_id])
  end
end
