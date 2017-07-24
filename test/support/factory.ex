defmodule Report.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Report.Repo
  alias Report.Replica.Declaration
  alias Report.Replica.DeclarationStatusHistory
  alias Report.Replica.Employee
  alias Report.Replica.Person
  alias Report.Replica.LegalEntity
  alias Report.Replica.MSP
  alias Report.Replica.Division
  alias Report.Replica.Region
  alias Report.Billing
  alias Report.ReportLog

  def declaration_factory do
    start_date = Faker.NaiveDateTime.forward(1)
    end_date   = NaiveDateTime.add(start_date, 31540000)
    %Declaration{
      declaration_request_id: Ecto.UUID.generate,
      start_date: start_date,
      end_date: end_date,
      status: "active",
      signed_at: start_date,
      created_by: Ecto.UUID.generate,
      updated_by: Ecto.UUID.generate,
      is_active: true,
      scope: ""
    }
  end

  def declaration_status_hstr_factory do
    %DeclarationStatusHistory{}
  end

  def make_declaration_with_all do
    :declaration
    |> build()
    |> declaration_with_employee
    |> declaration_with_person
    |> declaration_with_legal_entity
    |> insert
  end

  defp declaration_with_employee(%Declaration{} = declaration) do
    %{declaration | employee_id: insert(:employee).id}
  end

  defp declaration_with_person(%Declaration{} = declaration) do
    %{declaration | person_id: insert(:person).id}
  end

  defp declaration_with_legal_entity(%Declaration{} = declaration) do
    division =
      :division
      |> build()
      |> division_with_legal_entity
      |> insert()
    %{declaration | legal_entity_id: division.legal_entity_id, division_id: division.id}
  end

  defp division_with_legal_entity(%Division{} = divison) do
    %{divison | legal_entity_id: insert(:legal_entity).id}
  end

  def employee_factory do
    start_date = Faker.Date.forward(-2)
    end_date   = Faker.Date.forward(365)
    %Employee{
      employee_type: "doctor",
      position: Faker.Pokemon.name,
      start_date: start_date,
      end_date: end_date,
      status_reason: Faker.Beer.style,
      inserted_by: Ecto.UUID.generate,
      updated_by: Ecto.UUID.generate,
      status: "APPROVED",
      is_active: true
    }
  end

  def division_factory do
    bool_list = [true, false]
    %Division{
      email: sequence(:email, &"division-#{&1}@example.com"),
      name: Faker.Pokemon.name,
      status: "ACTIVE",
      is_active: true,
      type: "clinic",
      addresses: [%{"zip": "02090", "area": "ЛЬВІВСЬКА",
                   "type": "REGISTRATION", "region": "ПУСТОМИТІВСЬКИЙ",
                   "street": "вул. Ніжинська", "country": "UA",
                   "building": "15", "apartment": "23",
                   "settlement": "СОРОКИ-ЛЬВІВСЬКІ", "street_type": "STREET",
                   "settlement_id": "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
                   "settlement_type": "CITY"}],
      phones: [%{"type": "MOBILE", "number": "+380503410870"}],
      mountain_group: Enum.at(bool_list, :rand.uniform(2) - 1)
    }
  end

  def person_factory do
    %Person{
      birth_date: Faker.Date.date_of_birth(19..70)
    }
  end

  def legal_entity_factory do
    %LegalEntity{
      is_active: true,
      addresses: [%{}],
      edrpou: sequence(:edrpou, &"2007772#{&1}"),
      email: sequence(:email, &"legal-entity-#{&1}@example.com"),
      kveds: ["test"],
      legal_form: Faker.Pokemon.name,
      name: Faker.Pokemon.name,
      owner_property_type: Faker.Beer.style,
      public_name: Faker.Company.name,
      short_name: Faker.Company.suffix,
      status: "active",
      type: "Hospital",
      inserted_by: Ecto.UUID.generate,
      updated_by: Ecto.UUID.generate,
      created_by_mis_client_id: Ecto.UUID.generate,
      medical_service_provider: build(:msp)
    }
  end

  def msp_factory do
    %MSP{
      accreditation: %{test: "test"},
      licenses: [%{test: "test"}],
    }
  end

  def msp_with_legal_entity(%MSP{} = msp) do
    insert(:legal_entity, medical_service_provider: msp)
  end

  def billing_factory do
    declaration = make_declaration_with_all()
    %Billing{
      billing_date: Faker.Date.forward(-30),
      declaration_id: declaration.id,
      legal_entity_id: declaration.legal_entity_id,
      person_age: :rand.uniform(65),
      mountain_group: Enum.at(["true", "false"], :rand.uniform(2) - 1)
    }
  end

  def report_log_factory do
    %ReportLog{
      type: "capitation",
      public_url: Faker.Internet.url
    }
  end

  def region_factory do
    %Region{
      name: "ЛЬВІВСЬКА"
    }
  end
end
