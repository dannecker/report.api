defmodule Report.Replica.DeclarationStatusHistory do
  @moduledoc false
  use Ecto.Schema

  schema "declarations_status_hstr" do
    field :status, :string

    belongs_to :declaration, Report.Replica.Declaration, type: Ecto.UUID

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
