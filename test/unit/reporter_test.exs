defmodule Report.ReporterTest do
  @moduledoc false
  use Report.DataCase
  import Report.Factory
  alias Report.Reporter
  alias Report.Repo

  describe "Capitation report" do
    setup do
      for _ <- 0..14, do: make_declaration_with_all()
      :ok
    end

    test "generate_billing/0" do
      Reporter.generate_billing
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
end
