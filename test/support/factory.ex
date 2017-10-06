defmodule Report.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Report.Repo
  alias Report.Replica.Declaration
  alias Report.Replica.DeclarationStatusHistory
  alias Report.Replica.MedicationRequestStatusHistory
  alias Report.Replica.Employee
  alias Report.Replica.Person
  alias Report.Replica.LegalEntity
  alias Report.Replica.MSP
  alias Report.Replica.Division
  alias Report.Replica.Region
  alias Report.Replica.Party
  alias Report.Replica.PartyUser
  alias Report.Replica.MedicationRequest
  alias Report.Replica.MedicationDispense
  alias Report.Replica.MedicalProgram
  alias Report.Replica.Medication
  alias Report.Replica.MedicationDispense.Details
  alias Report.Billing
  alias Report.ReportLog
  alias Report.RedMSP
  alias Report.RedMSPTerritory
  alias Ecto.UUID

  def declaration_factory do
    start_date = Faker.NaiveDateTime.forward(1)
    end_date   = NaiveDateTime.add(start_date, 31540000)
    %Declaration{
      declaration_request_id: UUID.generate,
      start_date: start_date,
      end_date: end_date,
      status: "active",
      signed_at: start_date,
      created_by: UUID.generate,
      updated_by: UUID.generate,
      is_active: true,
      scope: ""
    }
  end

  def declaration_status_hstr_factory do
    %DeclarationStatusHistory{}
  end

  def medication_request_status_hstr_factory do
    %MedicationRequestStatusHistory{}
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
    %{declaration | employee_id: insert(:employee, legal_entity: nil).id}
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
      inserted_by: UUID.generate,
      updated_by: UUID.generate,
      status: "APPROVED",
      is_active: true,
      party: build(:party),
      legal_entity: build(:legal_entity),
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
      addresses: [
        %{
          "zip": "02090", "area": "ЛЬВІВСЬКА",
          "type": "REGISTRATION", "region": "ПУСТОМИТІВСЬКИЙ",
          "street": "вул. Ніжинська", "country": "UA",
          "building": "15", "apartment": "23",
          "settlement": "СОРОКИ-ЛЬВІВСЬКІ", "street_type": "STREET",
          "settlement_id": "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
          "settlement_type": "CITY"
        },
        %{
          "zip": "02090", "area": "ЛЬВІВСЬКА", "type": "RESIDENCE", "region": "ПУСТОМИТІВСЬКИЙ",
          "street": "Ніжинська", "country": "UA", "building": "115", "apartment": "3",
          "settlement": "СОРОКИ-ЛЬВІВСЬКІ", "street_type": "STREET",
          "settlement_id": "707dbc55-cb6b-4aaa-97c1-2a1e03476100", "settlement_type": "CITY"
        }
      ],
      phones: [%{"type": "MOBILE", "number": "+380503410870"}],
      mountain_group: Enum.at(bool_list, :rand.uniform(2) - 1)
    }
  end

  def person_factory do
    %Person{
      birth_date: Faker.Date.date_of_birth(19..70),
      addresses: [
        %{"zip": "02090", "area": "ЛЬВІВСЬКА", "type": "REGISTRATION",
        "region": "ПУСТОМИТІВСЬКИЙ", "street": "Ніжинська", "country": "UA", "building": "15", "apartment": "23",
        "settlement": "СОРОКИ-ЛЬВІВСЬКІ",
        "street_type": "STREET",
        "settlement_id": "707dbc55-cb6b-4aaa-97c1-2a1e03476100", "settlement_type": "CITY"},
        %{"zip": "02090", "area": "ЛЬВІВСЬКА", "type": "RESIDENCE", "region": "ПУСТОМИТІВСЬКИЙ",
        "street": "Ніжинська", "country": "UA", "building": "15", "apartment": "23",
        "settlement": "СОРОКИ-ЛЬВІВСЬКІ", "street_type": "STREET",
        "settlement_id": "707dbc55-cb6b-4aaa-97c1-2a1e03476100", "settlement_type": "CITY"}
      ]
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
      status: "ACTIVE",
      type: "MSP",
      inserted_by: UUID.generate,
      updated_by: UUID.generate,
      created_by_mis_client_id: UUID.generate,
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
      mountain_group: Enum.at(["true", "false"], :rand.uniform(2) - 1),
      compensation_group: "test",
      decision_id: "id"
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

  def red_msp_territory_factory do
    %RedMSPTerritory{
      settlement_id: UUID.generate,
      street_type: "street",
      street_name: Faker.Address.street_name,
      postal_code: Faker.Address.zip,
      buildings: "1,2,3",
      red_msp: build(:red_msp)
    }
  end

  def red_msp_factory do
    %RedMSP{
      name: Faker.App.name,
      edrpou: sequence(:edrpou, &"2007772#{&1}"),
      type: "general",
      population_count: :rand.uniform(10000)
    }
  end

  def party_factory do
    %Party{
      birth_date: ~D[1991-08-19],
      documents: [],
      first_name: "some first_name",
      gender: "some gender",
      last_name: "some last_name",
      phones: [],
      second_name: "some second_name",
      tax_id: "some tax_id",
      inserted_by: UUID.generate(),
      updated_by: UUID.generate()
    }
  end

  def party_user_factory do
    %PartyUser{party: build(:party), user_id: UUID.generate()}
  end

  def medical_program_factory do
    %MedicalProgram{
      id: UUID.generate(),
      is_active: true,
      name: "test",
      inserted_by: UUID.generate,
      updated_by: UUID.generate,
    }
  end

  def medication_dispense_factory do
    %MedicationDispense{
      id: UUID.generate(),
      status: "NEW",
      inserted_by: UUID.generate,
      updated_by: UUID.generate,
      is_active: true,
      dispensed_at: to_string(Date.utc_today),
      party: build(:party),
      legal_entity: build(:legal_entity),
      payment_id: UUID.generate(),
      division: build(:division),
      medical_program: build(:medical_program),
      medication_request: build(:medication_request),
    }
  end

  def medication_request_factory do
    %MedicationRequest{
      id: UUID.generate(),
      status: "ACTIVE",
      inserted_by: UUID.generate,
      updated_by: UUID.generate,
      is_active: true,
      person_id: UUID.generate(),
      employee: build(:employee),
      division: build(:division),
      medication: build(:medication),
      created_at: NaiveDateTime.utc_now(),
      started_at: NaiveDateTime.utc_now(),
      ended_at: NaiveDateTime.utc_now(),
      dispense_valid_from: Date.utc_today(),
      dispense_valid_to: Date.utc_today(),
      medication_qty: 0,
      medication_request_requests_id: UUID.generate(),
      request_number: "",
      medical_program: build(:medical_program),
      rejected_at: Date.utc_today(),
      rejected_by: UUID.generate(),
    }
  end

  def medication_factory do
    %Medication{
      name: "Prednisolonum Forte",
      type: "BRAND",
      form: "Pill",
      container: %{
        numerator_unit: "pill",
        numerator_value: 1,
        denumerator_unit: "pill",
        denumerator_value: 1
      },
      manufacturer: %{
        name: "ПАТ `Київський вітамінний завод`",
        country: "UA"
      },
      package_qty: 30,
      package_min_qty: 10,
      certificate: to_string(3_300_000_000 + :rand.uniform(99_999_999)),
      certificate_expired_at: ~D[2012-04-17],
      is_active: true,
      code_atc: "C08CA0",
      updated_by: UUID.generate(),
      inserted_by: UUID.generate(),
    }
  end

  def medication_dispense_details_factory do
    %Details{
      medication_id: UUID.generate(),
      medication_qty: 5.45,
      sell_price: 6.66,
      reimbursement_amount: 4.5,
      medication_dispense_id: UUID.generate(),
      sell_amount: 5,
      discount_amount: 10
    }
  end
end
