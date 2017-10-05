defmodule Report.Replica.Meta.Phone do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  schema "phones" do
    field :type, :string
    field :number, :string
  end
end
