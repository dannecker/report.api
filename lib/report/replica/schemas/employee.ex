defmodule Report.Replica.Employee do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "employees" do
    field :employee_type, :string
    field :is_active, :boolean, default: false
    field :position, :string
    field :start_date, :date
    field :end_date, :date
    field :status, :string
    field :status_reason, :string
    field :updated_by, Ecto.UUID
    field :inserted_by, Ecto.UUID

    belongs_to :party, Report.Replica.Party, type: Ecto.UUID
    belongs_to :division, Report.Replica.Division, type: Ecto.UUID
    belongs_to :legal_entity, Report.Replica.LegalEntity, type: Ecto.UUID

    has_one :doctor, Report.Replica.EmployeeDoctor
    has_many :declarations, Report.Replica.Declaration

    timestamps(type: :utc_datetime)
  end
end
