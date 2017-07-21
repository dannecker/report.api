defmodule Report.Repo.Migrations.ChangeDeclarations do
  use Ecto.Migration

  def change do
    alter table(:declarations) do
      remove :declaration_signed_id
    end

    execute "alter table declarations alter column employee_id type uuid using employee_id::uuid;"
    execute "alter table declarations alter column person_id type uuid using person_id::uuid;"
    execute "alter table declarations alter column legal_entity_id type uuid using legal_entity_id::uuid;"
  end
end
