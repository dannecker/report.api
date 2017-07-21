defmodule Report.Replica.Declaration do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "declarations" do
    field :employee_id, Ecto.UUID
    field :start_date, Timex.Ecto.Date
    field :end_date, Timex.Ecto.Date
    field :status, :string
    field :signed_at, :utc_datetime
    field :created_by, Ecto.UUID
    field :updated_by, Ecto.UUID
    field :is_active, :boolean, default: false
    field :scope, :string
    field :declaration_request_id, Ecto.UUID

    belongs_to :division, Report.Replica.Division, type: Ecto.UUID
    belongs_to :person, Report.Replica.Person, type: Ecto.UUID
    belongs_to :legal_entity, Report.Replica.LegalEntity, type: Ecto.UUID

    timestamps(type: :utc_datetime)
  end
end
