defmodule Report.Replica.Meta.Document do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  schema "documents" do
    field :type, :string
    field :number, :string
  end
end
