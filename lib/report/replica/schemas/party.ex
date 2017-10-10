defmodule Report.Replica.Party do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "parties" do
    field :first_name, :string
    field :last_name, :string
    field :second_name, :string

    has_many :users, Report.Replica.PartyUser, foreign_key: :party_id

    timestamps()
  end
end
