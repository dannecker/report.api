defmodule Report.Replica.Person do
  @moduledoc false
  use Ecto.Schema
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @derive {Poison.Encoder, except: [:__meta__]}
  schema "persons" do
    field :birth_date, :date
    field :death_date, :date
    field :addresses, {:array, :map}
    timestamps(type: :utc_datetime)
  end
end
