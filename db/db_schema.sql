
-- CICJF database schema
-- Mitchell Angelos
-- Created 10/24/21
-- Edited 10/25/21
-- Recent edit note(s): Added foreign key reference constraint for county_fips in FacilitySamples

-- Table for sample data for counties
CREATE TABLE IF NOT EXISTS CountySamples (
  _id INT AUTO_INCREMENT UNIQUE,
  fips INT,
  county_date DATE,
  county VARCHAR(75),
  state VARCHAR(75),
  cases INT,
  deaths INT,
  latitude DOUBLE,
  longitude DOUBLE,
  PRIMARY KEY (_id),
  INDEX(fips)
);

-- Table for sample data for individual facilities
CREATE TABLE IF NOT EXISTS FacilitySamples (
  _id INT AUTO_INCREMENT UNIQUE,
  name VARCHAR(75),
  city VARCHAR(75),
  county VARCHAR(75),
  county_fips INT,
  state VARCHAR(75),
  latitude DOUBLE,
  longitude DOUBLE,
  facility_date DATE,
  confirmed_cases INT,
  deaths INT,
  address VARCHAR(75),
  zipcode INT,
  PRIMARY KEY (_id),
  CONSTRAINT county_fips
    FOREIGN KEY (county_fips)
    REFERENCES CountySamples (fips)
);
