defmodule Report.Integration.MainStatsTest do
  use Report.Web.ConnCase

  alias Report.Stats.MainStats

  test "test main_stats_by_period/1" do
    employee = insert(:employee, employee_type: "DOCTOR")
    person = insert(:person)
    legal_entity = insert(:legal_entity)
    division = insert(:division, legal_entity_id: legal_entity.id)
    insert(:legal_entity)
    declaration1 = insert(:declaration,
      employee_id: employee.id,
      person_id: person.id,
      legal_entity_id: legal_entity.id,
      division_id: division.id,
      status: "active",
    )
    declaration2 = insert(:declaration,
      employee_id: employee.id,
      person_id: person.id,
      legal_entity_id: legal_entity.id,
      division_id: division.id,
      status: "terminated",
    )
    insert(:declaration_status_hstr, declaration_id: declaration1.id, status: declaration1.status)
    insert(:declaration_status_hstr, declaration_id: declaration1.id, status: "terminated")
    insert(:declaration_status_hstr, declaration_id: declaration1.id, status: declaration1.status)
    insert(:declaration_status_hstr, declaration_id: declaration2.id, status: declaration2.status)

    from_date = "2017-01-01"
    to_date = to_string(Date.utc_today())

    {:ok, main_stats} = MainStats.get_main_stats(%{"from_date" => from_date, "to_date" => to_date})
    schema =
      "test/data/stats/main_stats_response.json"
      |> File.read!()
      |> Poison.decode!()

    schema = Map.put(schema, "properties", get_in(schema, ~w(properties data properties)))
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert %{"from_date" => ^from_date, "to_date" => ^to_date} = main_stats
    assert %{"declarations_closed" => 1,
             "declarations_created" => 1,
             "declarations_total" => 2,
             "doctors" => 1,
             "msps" => 2} = main_stats["period"]
    assert %{"declarations_closed" => 1,
             "declarations_created" => 1,
             "declarations_total" => 2,
             "doctors" => 1,
             "msps" => 2} = main_stats["total"]
  end
end
