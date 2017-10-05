defmodule Report.Replica.MedicalProgram do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "medical_programs" do
    field :name, :string
    field :is_active, :boolean, default: true
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    timestamps()
  end
end
