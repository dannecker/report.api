defmodule Report.Repo.Migrations.AddDeclarationRequestIdToDecl do
  use Ecto.Migration

  def change do
    alter table(:declarations) do
      add :declaration_request_id, :uuid
    end

    # This will update existing declarations with UUIDs referring to non-existing declaration_requests.
    # The code at this point is not in production, so it's safe to do this (another option would be dropping
    # existing data)
    execute ~s(create extension "uuid-ossp";)
    execute "update declarations set declaration_request_id = uuid_generate_v4() where declaration_request_id is null;"

    alter table(:declarations) do
      modify :declaration_request_id, :uuid, null: false
    end
  end
end
