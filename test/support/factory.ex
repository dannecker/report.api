defmodule Report.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Report.Repo
  alias Report.Replica.Declaration
  alias Report.Replica.Employee
  alias Report.Replica.Person
  alias Report.Replica.LegalEntity
  alias Report.Replica.MSP

  def declaration_factory do
    start_date = Faker.NaiveDateTime.forward(1)
    end_date   = NaiveDateTime.add(start_date, 31540000)
    %Declaration{
      declaration_signed_id: Ecto.UUID.generate,
      start_date: start_date,
      end_date: end_date,
      status: "",
      signed_at: start_date,
      created_by: Ecto.UUID.generate,
      updated_by: Ecto.UUID.generate,
      is_active: true,
      scope: "",
      division_id: Ecto.UUID.generate,
    }
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
    %{declaration | legal_entity_id: insert(:legal_entity).id}
  end

  def employee_factory do
    start_date = Faker.Date.forward(-2)
    end_date   = Faker.Date.forward(365)
    %Employee{
      employee_type: "doctor",
      position: Faker.Pokemon.name,
      start_date: start_date,
      end_date: end_date,
      status: Faker.Pokemon.name,
      status_reason: Faker.Beer.style,
      inserted_by: Ecto.UUID.generate,
      updated_by: Ecto.UUID.generate,
      status: "active",
      is_active: true
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

  def declaration_with_person
end
