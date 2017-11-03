defmodule Report.RedLists do
  @moduledoc """
    Context module for Red Lists
  """
  import Ecto.Query
  alias Report.Repo
  alias Report.RedMSPTerritory
  alias Report.Billing
  alias Report.Replica.Declaration
  alias Report.RedMSP

  def find_msp_territory(settlement_id) do
    query =
      from mspt in RedMSPTerritory,
      where: mspt.settlement_id == ^settlement_id,
      preload: [:red_msp]

    Repo.all(query)
  end

  def find_msp_territory(settlement_id, street_type, street_name, building) do
    query =
      from mspt in RedMSPTerritory,
      where: mspt.settlement_id == ^settlement_id,
      where: mspt.street_type == ^street_type,
      where: mspt.street_name == ^street_name,
      where: ilike(mspt.buildings, ^"%#{building}%"),
      preload: [:red_msp]

    Repo.all(query)
  end

  def find_msp_by_type(mspt_list, type) do
    mspt = Enum.find(mspt_list, nil, fn l -> l.red_msp.type == type end)
    mspt.red_msp.id
  end

  def find_red_list_gone_green(red_msp_ids) do
    query =
      from b in Billing,
      where: not is_nil(b.red_msp_id),
      where: b.red_msp_id in ^red_msp_ids,
      select: count(b.id)
    Repo.one(query)
  end

  def person_already_found_in_red_lists?(person_id) do
    query =
      from b in Billing,
      join: d in Declaration, on: b.declaration_id == d.id,
      where: d.person_id == ^person_id,
      select: count(b.id)
    Repo.one(query) < 1
  end

  def get_red_msp_by_edrpou(edrpou) do
    query =
      from msp in RedMSP,
      where: msp.edrpou == ^edrpou,
      group_by: msp.id,
      select: [msp.id, msp.population_count]
    Repo.all(query)
  end
end
