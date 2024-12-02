CREATE TABLE natural_key_example (
    license_id text CONSTRAINT license_key PRIMARY KEY,
    first_name text,
    last_name text
);

DROP TABLE natural_key_example;

CREATE TABLE natural_key_example (
    license_id text,
    first_name text,
    last_name text,
    CONSTRAINT license_key PRIMARY KEY (license_id)
);

INSERT INTO natural_key_example (
    license_id, first_name, last_name
)
VALUES ('T229901', 'Gem', 'Godfrey');

INSERT INTO natural_key_example (
    license_id, first_name, last_name
)
VALUES ('T229901', 'John', 'Mitchell');

CREATE TABLE natural_key_composite_example (
    student_id text,
    school_day date,
    present boolean,
    CONSTRAINT student_key PRIMARY KEY (student_id, school_day)
);

INSERT INTO natural_key_composite_example (
    student_id, school_day, present
)
VALUES (775, '2022-01-22', 'Y');

INSERT INTO natural_key_composite_example (
    student_id, school_day, present
)
VALUES (775, '2022-01-23', 'Y');

INSERT INTO natural_key_composite_example (
    student_id, school_day, present
)
VALUES (775, '2022-01-23', 'N');

CREATE TABLE surrogate_key_example (
    order_number bigint GENERATED ALWAYS AS IDENTITY,
    product_name text,
    order_time timestamp with time zone,
    CONSTRAINT order_number_key PRIMARY KEY (order_number)
);

INSERT INTO surrogate_key_example (
    product_name, order_time
)
VALUES ('Beachball Polish', '2020-03-15 09:21-07'),
       ('Wrinkle De-Atomiser', '2017-05-22 14:00-07'),
       ('Flux Capacitor', '1985-10-26 01:18:00-07');

SELECT * FROM surrogate_key_example;

INSERT INTO surrogate_key_example
OVERRIDING SYSTEM VALUE
VALUES (4, 'Chicken Coop', '2021-09-03 10:33-06');

ALTER TABLE surrogate_key_example ALTER COLUMN order_number
RESTART WITH 5;

INSERT INTO surrogate_key_example (
    product_name, order_time
)
VALUES ('Aloe Plant', '2020-03-15 10:09-07');

SELECT * FROM surrogate_key_example;

CREATE TABLE licenses (
    license_id text,
    first_name text,
    last_name text,
    CONSTRAINT licenses_key PRIMARY KEY (license_id)
);

CREATE TABLE registrations (
    registration_id text,
    registration_date timestamp with time zone,
    license_id text REFERENCES licenses (license_id),
    CONSTRAINT registration_key PRIMARY KEY (
		registration_id, license_id
	)
);

INSERT INTO licenses (
    license_id, first_name, last_name
)
VALUES ('T229901', 'Steve', 'Rothery');

INSERT INTO registrations (
    registration_id, registration_date, license_id
)
VALUES ('A203391', '2022-03-17', 'T229901');

INSERT INTO registrations (
    registration_id, registration_date, license_id
)
VALUES ('A75772', '2022-03-17', 'T000001');

CREATE TABLE unique_constraint_example (
    contact_id bigint GENERATED ALWAYS AS IDENTITY,
    first_name text,
    last_name text,
    email text,
    CONSTRAINT contract_id_key PRIMARY KEY (contact_id),
    CONSTRAINT email_unique UNIQUE (email)  
);

INSERT INTO unique_constraint_example (
    first_name, last_name, email
)
VALUES ('Samantha', 'Lee', 'slee@example.org');

INSERT INTO unique_constraint_example (
    first_name, last_name, email
)
VALUES ('Betty', 'Diaz', 'bdiaz@example.org');

INSERT INTO unique_constraint_example (
    first_name, last_name, email
)
VALUES ('Sasha', 'Lee', 'slee@example.org');

CREATE TABLE not_null_example (
    student_id bigint GENERATED ALWAYS AS IDENTITY,
    first_name text NOT NULL,
    last_name text NOT NULL,
    CONSTRAINT student_id_key PRIMARY KEY (student_id)
);

ALTER TABLE not_null_example 
	DROP CONSTRAINT student_id_key;

ALTER TABLE not_null_example 
	ADD CONSTRAINT student_id_key
    PRIMARY KEY (student_id);

ALTER TABLE not_null_example ALTER COLUMN first_name
    DROP NOT NULL;

ALTER TABLE not_null_example ALTER COLUMN first_name
    SET NOT NULL;

CREATE TABLE new_york_addresses (
    longitude numeric(9, 6),
    latitude numeric(9, 6),
    street_number text,
    street text,
    unit text,
    postcode text,
    id integer CONSTRAINT new_york_key PRIMARY KEY
);

COPY new_york_addresses
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_08/city_of_new_york.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM new_york_addresses;

EXPLAIN ANALYZE SELECT * FROM new_york_addresses
WHERE street = 'BROADWAY';

EXPLAIN ANALYZE SELECT * FROM new_york_addresses
WHERE street = '52 STREET';

EXPLAIN ANALYSE SELECT * FROM new_york_addresses
WHERE street = 'ZWICKY AVENUE';

CREATE INDEX street_idx
ON new_york_addresses (street);

EXPLAIN ANALYZE SELECT * FROM new_york_addresses
WHERE street = 'BROADWAY';

EXPLAIN ANALYZE SELECT * FROM new_york_addresses
WHERE street = '52 STREET';

EXPLAIN ANALYSE SELECT * FROM new_york_addresses
WHERE street = 'ZWICKY AVENUE';
