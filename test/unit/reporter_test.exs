defmodule Report.ReporterTest do
  @moduledoc false
  use Report.DataCase, async: true
  import Report.Factory
  alias Report.Reporter
  alias Report.Repo

  describe "Capitation report" do
    setup do
      for _ <- 0..14, do: make_declaration_with_all()
      :ok
    end

    test "generate_billing/0" do
      Reporter.generate_billing()
      billings = Repo.all(Report.Billing)
      assert length(billings) == 15

      for _ <- 0..14, do: make_declaration_with_all()
      Reporter.generate_billing
      billings = Repo.all(Report.Billing)
      assert length(billings) == 45
    end

    test "generate_billing not using terminated declarations" do
      Reporter.generate_billing
      billings = Repo.all(Report.Billing)
      assert length(billings) == 15
      Repo.update_all(Report.Replica.Declaration, set: [status: "terminated"])
      for _ <- 0..14, do: make_declaration_with_all()
      Reporter.generate_billing
      billings = Repo.all(Report.Billing)
      assert length(billings) == 30
      assert Enum.all?(billings, &(Map.get(&1, :is_valid)))
    end

    test "generate_billing updates person age in billing" do
      declaration =
        Report.Replica.Declaration
        |> first()
        |> preload(:person)
        |> Repo.one

      chset = Ecto.Changeset.change(declaration.person, birth_date: ~D[2000-01-01])
      Repo.update(chset)

      Reporter.generate_billing

      bill =
        Report.Billing
        |> where(declaration_id: ^declaration.id)
        |> first
        |> Repo.one


      b =
        Report.Replica.Declaration
        |> where(person_id: ^declaration.person.id)
        |> preload(:person)
        |> Repo.one()

      assert bill.person_age == Timex.diff(Timex.today, b.person.birth_date, :years)
      chset = Ecto.Changeset.change(declaration.person, birth_date: ~D[2010-01-01])
      Repo.update(chset)

      Reporter.generate_billing

      b =
        Report.Replica.Declaration
        |> where(person_id: ^declaration.person.id)
        |> last
        |> preload(:person)
        |> Repo.one()
      assert 7 == Timex.diff(Timex.today, b.person.birth_date, :years)
    end
  end

  describe "Capitation report with custom data" do
    test "generate_csv/0" do
      les = generate_declarations()
      Reporter.generate_billing()
      Reporter.generate_csv
      data =
        "/tmp/#{Timex.today}.csv"
        |> File.stream!()
        |> CSV.decode()
        |> Enum.to_list
      assert length(data) == 19
      assert data |> Enum.filter(fn {_, d} -> Enum.at(d, 0) in Enum.map(les, &(&1.edrpou)) end) |> length == 9
    end

    test "capitation/0" do
      generate_declarations()
      Reporter.capitation
      assert length(Repo.all(Report.ReportLog)) == 1
    end

    test "capitation with red lists" do
      generate_declarations()
      declaration = Report.Replica.Declaration |> Repo.all() |> Repo.preload([:legal_entity, :person]) |> List.last
      address = declaration.person.addresses |> Enum.filter(fn i -> i["type"] == "REGISTRATION" end) |> List.first
      insert(:red_msp_territory, %{
          settlement_id: address["settlement_id"],
          street_name: address["street_name"],
          buildings: address["buildings"],
          red_msp: %{
            name: "test", type: "general",
            edrpou: declaration.legal_entity.edrpou,
            population_count: :rand.uniform(10000)
                  }
      })
      insert(:red_msp_territory, %{
          settlement_id: address["settlement_id"],
          street_name: address["street_name"],
          buildings: address["buildings"],
          red_msp: %{
            name: "test", type: "general",
            edrpou: "30077721",
            population_count: :rand.uniform(10000)
                  }
      })
      Reporter.capitation
      assert length(Repo.all(Report.ReportLog)) == 1
      data =
        "/tmp/#{Timex.today}.csv"
        |> File.stream!()
        |> CSV.decode()
        |> Enum.to_list
      assert length(data) == 22
      {:ok, [_, _, _, _, _, _, _, _, population_count, green, diff]} = Enum.at(data, 2)
      assert  String.to_integer(diff) == (String.to_integer(population_count) - String.to_integer(green))
    end

    defp generate_declarations do
      les = insert_list(3, :legal_entity)
      le = insert_list(3, :legal_entity)
      division = for _ <- 0..29, do: insert(:division, %{legal_entity_id: Enum.random(le).id})
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
      les
    end
  end
end
