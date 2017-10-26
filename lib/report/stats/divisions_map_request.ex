defmodule Report.Stats.DivisionsMapRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  @type_clinic "CLINIC"
  @type_ambulant "AMBULANT_CLINIC"
  @type_fap "FAP"
  @type_drugstore "DRUGSTORE"
  @type_drugstore_point "DRUGSTORE_POINT"

  schema "divisions_map" do
    field :type, :string
    field :name, :string
    field :lefttop_latitude, :float
    field :lefttop_longitude, :float
    field :rightbottom_latitude, :float
    field :rightbottom_longitude, :float
  end

  def type(:clinic), do: @type_clinic
  def type(:ambulant), do: @type_ambulant
  def type(:fap), do: @type_fap
  def type(:drugstore), do: @type_drugstore
  def type(:drugstore_point), do: @type_drugstore_point

  def types do
    Enum.map(~w(clinic ambulant fap drugstore drugstore_point)a, &type/1)
  end
end
