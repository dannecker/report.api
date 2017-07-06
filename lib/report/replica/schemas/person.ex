defmodule Report.Replica.Person do
  @moduledoc false
  use Ecto.Schema
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @derive {Poison.Encoder, except: [:__meta__]}
  schema "persons" do
    field :version, :string, default: "default"
    field :first_name, :string
    field :last_name, :string
    field :second_name, :string
    field :birth_date, :date
    field :birth_place, :string
    field :gender, :string
    field :email, :string
    field :tax_id, :string
    field :death_date, :date
    field :is_active, :boolean, default: true
    embeds_many :documents, Document, on_replace: :delete do
      field :type, :string
      field :number, :string
      field :issue_date, :utc_datetime
      field :expiration_date, :utc_datetime
      field :issued_by, :string
    end
    embeds_many :addresses, Address, on_replace: :delete do
      field :type, :string
      field :country, :string
      field :area, :string
      field :region, :string
      field :city, :string
      field :city_type, :string
      field :street, :string
      field :building, :string
      field :apartment, :string
      field :zip, :string
    end
    embeds_many :phones, Phone, on_replace: :delete do
      field :type, :string
      field :number, :string
    end
    field :secret, :binary
    embeds_one :emergency_contact, EmergencyContact, on_replace: :delete do
      field :first_name, :string
      field :last_name, :string
      field :second_name, :string
      embeds_many :phones, Phone, on_replace: :delete do
        field :type, :string
        field :number, :string
      end
    end
    embeds_one :confidant_person, ConfidantPerson, on_replace: :delete do
      field :first_name, :string
      field :last_name, :string
      field :second_name, :string
      field :birth_date, :date
      field :birth_place, :string
      field :gender, :string
      field :tax_id, :string
      embeds_many :phones, Phone, on_replace: :delete do
        field :type, :string
        field :number, :string
      end
      embeds_many :documents, Document, on_replace: :delete do
        field :type, :string
        field :number, :string
        field :issue_date, :utc_datetime
        field :expiration_date, :utc_datetime
        field :issued_by, :string
      end
    end
    field :status, :string
    field :inserted_by, :string, default: "default"
    field :updated_by, :string, default: "default"
    field :authentication_methods, {:array, :map}

    timestamps(type: :utc_datetime)
  end
end
