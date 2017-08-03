defmodule Report.RedLists do
  @moduledoc """
    Context module for Red Lists
  """
  import Ecto.Query
  alias Report.Repo
  alias Report.RedMSPTerritory

  def find_msp_territory(settlement_id) do
    query =
      from mspt in RedMSPTerritory,
      where: mspt.settlement_id == ^settlement_id,
      where: is_nil(mspt.street_name),
      preload: [:red_msp]

    Repo.all(query)
  end

  def find_msp_territory(settlement_id, street_name, building) do
    query =
      from mspt in RedMSPTerritory,
      where: mspt.settlement_id == ^settlement_id,
      where: mspt.street_name == ^street_name,
      where: ilike(mspt.buildings, ^building),
      preload: [:red_msp]

    Repo.all(query)
  end

  def find_msp_by_type(mspt_list, type) do
    mspt = Enum.find(mspt_list, nil, fn l -> l.red_msp.type == type end)
    mspt.red_msp.id
  end
end
