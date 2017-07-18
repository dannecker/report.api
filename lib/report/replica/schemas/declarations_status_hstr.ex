defmodule Report.Replica.DeclarationStatusHistory do
  @moduledoc false
  use Ecto.Schema

  schema "declarations_status_hstr" do
    field :declaration_id, Ecto.UUID
    field :status, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
