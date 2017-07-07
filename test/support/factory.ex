defmodule Report.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Report.Repo
  alias Report.Replica.Declaration
  alias Report.Replica.Employee

  # def declaration_factory do
  #   start_date = Faker.NaiveDateTime.forward(1)
  #   end_date   = NaiveDateTime.add(start_date, 31540000)
  #   %Declaration{
  #       declaration_signed_id: sequence(:uuid, &"5976423a-ee35-11e3-8569-14109ff1a304-#{&1}"),
  #       employee: build(:employee),
  #       person: build(:person),
  #       start_date: start_date,
  #       end_date: end_date,
  #       status: "",
  #       signed_at: start_date,
  #       created_by: sequence(:uuid, &"5976423a-ee35-11e3-8569-14109ff1a304-#{&1}"),
  #       is_active: true,
  #       scope: "",
  #       division_id: sequence(:uuid, &"5976423a-ee35-11e3-8569-14109ff1a304-#{&1}"),
  #       legal_enity: build(:legal_enity)
  #   }
  # end

  # def employee_factory do
  #   start_date = Faker.Date.forward(-2)
  #   end_date   = Faker.Date.forward(365)
  #   %Employee{
  #     employee_type: "doctor",
  #     position: Faker.Pokemon.name,
  #     start_date: start_date,
  #     end_date: end_date,
  #     status: Faker.Pokemon.name,
  #     status_reason: Faker.Beer.style,
  #     party: build(:party),
  #     devision: build(:division),

  #   }
  # end
end
