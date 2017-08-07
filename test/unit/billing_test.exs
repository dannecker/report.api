defmodule Report.BillingTest do
  @moduledoc false
  use Report.DataCase, async: false
  import Report.Factory
  alias Report.Billings
  alias Report.Billing
  alias Report.Repo

  describe "Billings API" do
    setup do
      billings = insert_list(15, :billing)
      billing =
        billings
        |> Enum.sort_by(&(Date.to_erl(&1.billing_date)))
        |> List.last
      %{billing: billing}
    end

    test "get_last_billing_date/0", %{billing: billing} do
      assert billing.billing_date == Billings.get_last_billing_date()
    end

    test "list_billing/1" do
      assert length(Billings.list_billing) == 15
    end

    test "todays_billing/1" do
      Repo.update_all(Billing, set: [billing_date: ~D[1970-01-01]])

      todays_billing = fn -> Billing |> Billings.todays_billing |> Billings.list_billing() end
      assert length(todays_billing.()) == 0
      Billing
      |> first
      |> Repo.one
      |> Ecto.Changeset.change(billing_date: Timex.today)
      |> Repo.update
      assert length(todays_billing.()) == 1
    end

    test "get_billing_for_csv/0" do
      Repo.update_all(Billing, set: [billing_date: Timex.today])
      {:ok, billings} = Repo.transaction(fn -> Billings.get_billing_for_capitation() |> Enum.to_list end)
      assert length(billings) == 15
    end

    test "without any billings get_last_billing_date/0" do
      Repo.delete_all(Report.Billing)
      make_declaration_with_all()
      assert Report.Replica.Replicas.get_oldest_declaration_date() == Billings.get_last_billing_date()
    end

    test "create_billing/1 from declaration" do
      Repo.delete_all(Report.Billing)
      make_declaration_with_all()
      declaration = Report.Replica.Replicas.list_declarations |> List.first
      billing = Billings.create_billing(declaration)
      assert declaration.id == billing.declaration.id
      assert declaration.legal_entity_id == billing.legal_entity_id
      assert declaration.division_id == billing.division_id
      assert declaration.division.mountain_group == billing.mountain_group
      assert billing.person_age == Timex.diff(Timex.today, declaration.person.birth_date, :years)
    end

    test "billing_changeset/4" do
      declaration = make_declaration_with_all() |> Repo.preload([:legal_entity, :person, :division])
      billing = Billings.billing_changeset(%Billing{}, declaration, declaration.person, declaration.division)
      assert billing.changes.mountain_group == declaration.division.mountain_group
      assert billing.changes.person_age == Timex.diff(Timex.today, declaration.person.birth_date, :years)
    end
  end

  describe "Billing API with custom billing records" do
    test "get_billing_for_csv/0 with created billing" do
      generate_declarations()
      Report.Reporter.generate_billing()
      {:ok, billing} = Repo.transaction(fn -> Billings.get_billing_for_capitation() |> Enum.to_list end)
      assert length(billing) in 5..10
    end
  end

  describe "Billings API works with RedLists" do
    setup do
      generate_declarations()
      persons = Repo.all(Report.Replica.Person)
      rand_person = Enum.random(persons)
      address = rand_person.addresses |> Enum.filter(fn i -> i["type"] == "REGISTRATION" end) |> List.first
      rmt = insert(:red_msp_territory, %{
          settlement_id: address["settlement_id"],
          street_name: address["street"],
          buildings: address["building"]
      })
      %{rmt: rmt}
    end
    test "billings matches with red_msps" do
      Report.Reporter.generate_billing()
      Billing
      |> Repo.all
      |> Enum.each(fn b -> assert b.red_msp_id end)
    end

    test "billings matches with red_msps and include decisions", %{rmt: rmt} do
      rmsp = insert(:red_msp, %{
        type: "child"
      })
      rmt = insert(:red_msp_territory, %{
          settlement_id: rmt.settlement_id,
          street_name: rmt.street_name,
          buildings: rmt.buildings
      })
      rmt |> Ecto.Changeset.change(red_msp_id: rmsp.id) |> Repo.update!
      person = Report.Replica.Person |> Ecto.Query.first |> Repo.one
      person |> Ecto.Changeset.change(birth_date: ~D[2016-01-01]) |> Repo.update
      Report.Reporter.generate_billing()
      mature_billed_msp = Billing |> where([b], b.person_age >= 18) |> Ecto.Query.first |> Repo.one
      child_billed_msp = Billing |> where([b], b.person_age < 18) |> Ecto.Query.first |> Repo.one
      assert child_billed_msp.red_msp_id == rmsp.id
      assert mature_billed_msp.red_msp_id != child_billed_msp.red_msp_id
    end

    test "billings matches with red_msps and selects red_msp_territory where street_name is nil", %{rmt: rmt} do
      rmt |> Ecto.Changeset.change(street_name: nil) |> Repo.update!
      insert(:red_msp_territory, %{
          settlement_id: rmt.settlement_id,
          street_name: "TEST",
          buildings: rmt.buildings
      })
      Report.Reporter.generate_billing()
      Billing
      |> Repo.all()
      |> Enum.each(fn b -> assert b.red_msp_id == rmt.red_msp_id end)
    end
  end

  defp generate_declarations do
    le = insert_list(5, :legal_entity)
    division = for _ <- 0..50, do: insert(:division, %{legal_entity_id: Enum.random(le).id})
    persons = insert_list(100, :person)
    Enum.each(persons,
      fn p ->
        d = Enum.random(division)
        insert(:declaration, %{
          legal_entity_id: d.legal_entity_id,
          person_id: p.id,
          division_id: d.id,
          employee_id: Ecto.UUID.generate()
          })
    end)
  end
end
