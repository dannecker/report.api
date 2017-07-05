defmodule Report.Replica.EmployeeDoctor do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "employee_doctors" do

    embeds_one :science_degree, ScienceDegree, on_replace: :delete, primary_key: false do
      field :country, :string
      field :city, :string
      field :degree, :string
      field :institution_name, :string
      field :diploma_number, :string
      field :speciality, :string
      field :issued_date, :date
    end

    embeds_many :qualifications, Qualification, on_replace: :delete, primary_key: false do
      field :type, :string
      field :institution_name, :string
      field :speciality, :string
      field :certificate_number, :string
      field :issued_date, :date
    end

    embeds_many :educations, Education, on_replace: :delete, primary_key: false do
      field :country, :string
      field :city, :string
      field :degree, :string
      field :institution_name, :string
      field :diploma_number, :string
      field :speciality, :string
      field :issued_date, :date
    end

    embeds_many :specialities, Speciality, on_replace: :delete, primary_key: false do
      field :speciality, :string
      field :speciality_officio, :boolean
      field :level, :string
      field :qualification_type, :string
      field :attestation_name, :string
      field :attestation_date, :date
      field :valid_to_date, :date
      field :certificate_number, :string
    end

    belongs_to :employee, Repo.Replica.Employee, type: Ecto.UUID

    timestamps()
  end
end
