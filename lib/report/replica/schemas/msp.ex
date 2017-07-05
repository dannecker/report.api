defmodule Report.Replica.MSP do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, warn: false

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "medical_service_providers" do
    field :accreditation, :map
    field :licenses, {:array, :map}

    belongs_to :legal_entity, Report.Replica.LegalEntity, type: Ecto.UUID

    timestamps(type: :utc_datetime)
  end
end
