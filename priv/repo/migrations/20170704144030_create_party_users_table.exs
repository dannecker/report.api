defmodule Report.Repo.Migrations.CreatePartyUsersTable do
  use Ecto.Migration

  def change do
    create table(:parties_party_users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, :uuid, null: false
      add :party_id, references(:parties, type: :uuid, on_delete: :nothing)

      timestamps()
    end
  end
end
