defmodule Report.Replica.PartyUser do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "party_users" do
    field :user_id, Ecto.UUID

    belongs_to :party, Report.Replica.Party, type: Ecto.UUID

    timestamps()
  end
end
