defmodule Report.Repo.Migrations.CreateBillingsTable do
  use Ecto.Migration

  def change do
    create table(:billings, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :billing_date, :date
      add :declaration_id, :uuid
      add :legal_entity_id, :uuid
      add :division_id, :uuid
      add :mountain_group, :string
      add :person_age, :integer
      timestamps(type: :utc_datetime)
    end
  end
end
