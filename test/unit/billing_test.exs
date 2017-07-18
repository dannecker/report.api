defmodule Report.BillingTest do
  @moduledoc false
  use Report.DataCase, async: true
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
end
