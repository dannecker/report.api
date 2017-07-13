defmodule Report.BillingTest do
  @moduledoc false
  use Report.DataCase, async: true
  import Report.Factory
  alias Report.Billings

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
      Report.Repo.delete_all(Report.Billing)
      make_declaration_with_all()
      assert Report.Replica.Replicas.get_oldest_declaration_date() == Billings.get_last_billing_date()
    end

    test "create_billing/1 from declaration" do
      declaration = make_declaration_with_all() |> Repo.preload([:person, :legal_entity])
      Billings.create_billing(declaration)
    end
  end
end
