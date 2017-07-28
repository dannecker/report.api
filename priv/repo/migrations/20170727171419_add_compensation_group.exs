defmodule Report.Repo.Migrations.AddCompensationGroup do
  use Ecto.Migration

  def change do
    alter table(:billings) do
      add :compensation_group, :string, null: false
      add :decision_id, :string, null: false
    end
  end
end
