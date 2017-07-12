defmodule Report.FactoryTest do
  use Report.DataCase
  import Report.Factory

  test "legal entity factory works" do
    assert %Report.Replica.LegalEntity{} = insert(:legal_entity)
  end

  test "declaration factory works as expect" do
    declaration = make_declaration_with_all()
    assert %Report.Replica.Declaration{} = declaration
    assert declaration.id == Repo.one(Report.Replica.Declaration).id
    assert declaration.person_id == Repo.one(Report.Replica.Person).id
    assert declaration.employee_id == Repo.one(Report.Replica.Employee).id
    assert declaration.legal_entity_id == Repo.one(Report.Replica.LegalEntity).id
  end
end
