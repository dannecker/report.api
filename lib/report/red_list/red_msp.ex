defmodule Report.RedMSP do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "red_msps" do
    field :name, :string, null: false
    field :edrpou, :string, null: false
    field :is_active, :boolean, null: false, default: true
    field :type, :string, null: false
    field :population_count, :integer, null: false
    timestamps(type: :utc_datetime)
  end
end
