CREATE TABLE public.legal_entities(
  id uuid NOT NULL,
  name CHARACTER varying(255) NOT NULL,
  short_name CHARACTER varying(255),
  public_name CHARACTER varying(255),
  status CHARACTER varying(255) NOT NULL,
  type CHARACTER varying(255) NOT NULL,
  owner_property_type CHARACTER varying(255) NOT NULL,
  legal_form CHARACTER varying(255) NOT NULL,
  edrpou CHARACTER varying(255) NOT NULL,
  kveds jsonb NOT NULL,
  addresses jsonb NOT NULL,
  phones jsonb,
  email CHARACTER varying(255),
  is_active BOOLEAN NOT NULL DEFAULT false,
  inserted_by uuid NOT NULL,
  updated_by uuid NOT NULL,
  inserted_at TIMESTAMP WITHOUT TIME zone NOT NULL,
  updated_at TIMESTAMP WITHOUT TIME zone NOT NULL,
  capitation_contract_id uuid,
  created_by_mis_client_id uuid,
  mis_verified CHARACTER varying(255) NOT NULL DEFAULT 'NOT_VERIFIED'::CHARACTER varying,
  nhs_verified BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id) );


CREATE TABLE public.divisions
(
  id uuid NOT NULL,
  external_id character varying(255),
  name character varying(255) NOT NULL,
  type character varying(255) NOT NULL,
  mountain_group character varying(255),
  addresses jsonb NOT NULL,
  phones jsonb NOT NULL,
  email character varying(255),
  inserted_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  legal_entity_id uuid,
  location geometry,
  status character varying(255) NOT NULL,
  is_active boolean NOT NULL DEFAULT false,
  PRIMARY KEY (id));


CREATE INDEX divisions_legal_entity_id_index
  ON public.divisions
  USING btree
  (legal_entity_id);

CREATE TABLE public.employees
(
  id uuid NOT NULL,
  "position" character varying(255) NOT NULL,
  status character varying(255) NOT NULL,
  employee_type character varying(255) NOT NULL,
  is_active boolean NOT NULL DEFAULT false,
  inserted_by uuid NOT NULL,
  updated_by uuid NOT NULL,
  start_date date NOT NULL,
  end_date date,
  legal_entity_id uuid,
  division_id uuid,
  party_id uuid,
  inserted_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  status_reason character varying(255),
  PRIMARY KEY (id));
 


CREATE INDEX employees_division_id_index
  ON public.employees
  USING btree
  (division_id);


CREATE INDEX employees_legal_entity_id_index
  ON public.employees
  USING btree
  (legal_entity_id);



CREATE INDEX employees_party_id_index
  ON public.employees
  USING btree
  (party_id);


CREATE TABLE public.employee_doctors
(
  id uuid NOT NULL,
  educations jsonb NOT NULL,
  qualifications jsonb,
  specialities jsonb NOT NULL,
  science_degree jsonb,
  employee_id uuid,
  inserted_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  PRIMARY KEY (id));

CREATE INDEX employee_doctors_employee_id_index
  ON public.employee_doctors
  USING btree
  (employee_id);


CREATE TABLE public.medical_service_providers
(
  id uuid NOT NULL,
  accreditation jsonb,
  licenses jsonb,
  inserted_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  legal_entity_id uuid,
  PRIMARY KEY (id));
  
CREATE INDEX medical_service_providers_legal_entity_id_index
  ON public.medical_service_providers
  USING btree
  (legal_entity_id);


CREATE TABLE public.parties
(
  id uuid NOT NULL,
  first_name character varying(255) NOT NULL,
  second_name character varying(255),
  last_name character varying(255) NOT NULL,
  birth_date date NOT NULL,
  gender character varying(255) NOT NULL,
  tax_id character varying(255) NOT NULL,
  documents jsonb,
  phones jsonb,
  inserted_by uuid NOT NULL,
  updated_by uuid NOT NULL,
  inserted_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  PRIMARY KEY (id)
);


CREATE TABLE public.party_users
(
  id uuid NOT NULL,
  user_id uuid NOT NULL,
  party_id uuid,
  inserted_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  PRIMARY KEY (id));
  

CREATE INDEX party_users_party_id_index
  ON public.party_users
  USING btree
  (party_id);

#\\\\\\\\\\\\\\\\\uadresses\\\\\\\\\\\\\\\\\\\\\\\

 CREATE TABLE public.districts
(
  id uuid NOT NULL,
  region_id uuid NOT NULL,
  name character varying(255) NOT NULL,
  inserted_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  koatuu character varying(10),
  PRIMARY KEY (id)
) ;

CREATE TABLE public.regions
(
  id uuid NOT NULL,
  name CHARACTER varying(50) NOT NULL,
  inserted_at TIMESTAMP WITHOUT TIME zone DEFAULT now(),
  updated_at TIMESTAMP WITHOUT TIME zone DEFAULT now(),
  koatuu CHARACTER varying(10),
  PRIMARY KEY (id)
);

CREATE TABLE public.streets
(
  id uuid NOT NULL,
  district_id uuid,
  region_id uuid,
  settlement_id uuid,
  street_type character varying(255),
  street_name character varying(255),
  postal_code character varying(255),
  numbers jsonb,
  inserted_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT streets_pkey PRIMARY KEY (id)
);



CREATE TABLE public.streets_aliases
(
  id uuid NOT NULL,
  street_id uuid NOT NULL,
  name character varying(255) NOT NULL,
  PRIMARY KEY (id)
);


CREATE TABLE public.settlements
(
  id uuid NOT NULL,
  district_id uuid,
  region_id uuid NOT NULL,
  name character varying(255) NOT NULL,
  mountain_group character varying(255) DEFAULT false,
  inserted_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  koatuu character varying(10),
  type character varying(50),
  parent_settlement_id uuid,
  PRIMARY KEY (id)
);



CREATE TABLE public.declarations
(
  id uuid NOT NULL,
  employee_id uuid NOT NULL,
  person_id uuid NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  status character varying(255) NOT NULL,
  signed_at timestamp without time zone NOT NULL,
  created_by uuid NOT NULL,
  updated_by uuid NOT NULL,
  is_active boolean DEFAULT false,
  scope character varying(255) NOT NULL,
  division_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  inserted_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL,
 PRIMARY KEY (id)
);

CREATE TABLE public.persons
(
  id uuid NOT NULL,
  birth_date timestamp without time zone NOT NULL,
  death_date timestamp without time zone,
  addresses jsonb,
  PRIMARY KEY (id));
