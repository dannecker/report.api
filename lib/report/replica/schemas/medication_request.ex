defmodule Report.Replica.MedicationRequest do
  @moduledoc false

  use Ecto.Schema

  @derive {Poison.Encoder, except: [:__meta__]}

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "medication_requests" do
    field :request_number, :string
    field :created_at, :date
    field :started_at, :date
    field :ended_at, :date
    field :dispense_valid_from, :date
    field :dispense_valid_to, :date
    field :person_id, Ecto.UUID
    field :employee_id, Ecto.UUID
    field :division_id, Ecto.UUID
    field :legal_entity_id, Ecto.UUID
    field :medication_id, Ecto.UUID
    field :medication_qty, :float
    field :status, :string
    field :is_active, :boolean
    field :rejected_at, :date
    field :rejected_by, Ecto.UUID
    field :reject_reason, :string
    field :medication_request_requests_id, Ecto.UUID
    field :medical_program_id, Ecto.UUID
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID
    field :verification_code, :string

    has_one :medication_dispense, Report.Replica.MedicationDispense
    belongs_to :employee, Report.Replica.Employee, define_field: false
    belongs_to :division, Report.Replica.Division, define_field: false
    belongs_to :medical_program, Report.Replica.MedicalProgram, define_field: false
    belongs_to :medication, Report.Replica.Medication, define_field: false
    belongs_to :legal_entity, Report.Replica.LegalEntity, define_field: false

    timestamps()
  end
end
