defmodule Report.Repo.Migrations.RemovePartyColumns do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      remove :birth_date
      remove :gender
      remove :tax_id
      remove :inserted_by
      remove :updated_by
      remove :phones
      remove :documents
    end
  end
end
