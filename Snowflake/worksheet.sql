
-- Create Storage Integration with S3
CREATE OR REPLACE STORAGE INTEGRATION PBI_Integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::149561018143:role/powerbi.role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://powerbi.project45/')
  COMMENT = 'Integration object for Power BI data project';

-- Describe integration
DESC INTEGRATION PBI_Integration;

-- Create database and schema
CREATE DATABASE PowerBI;
CREATE SCHEMA PBI_Data;

-- Create main dataset table
CREATE TABLE PBI_Dataset (
  Year INT,
  Location STRING,
  Area INT,
  Rainfall FLOAT,
  Temperature FLOAT,
  Soil_type STRING,
  Irrigation STRING,
  Yeilds INT,
  Humidity FLOAT,
  Crops STRING,
  Price INT,
  Season STRING
);

-- Verify table
SELECT * FROM PBI_Dataset;

-- Create stage to connect with S3
CREATE STAGE PowerBI.PBI_Data.pbi_stage
  URL = 's3://powerbi.project45'
  STORAGE_INTEGRATION = PBI_Integration;

-- Load data from S3 into Snowflake table
COPY INTO PBI_Dataset
FROM @pbi_stage
FILE_FORMAT = (TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';

-- Check files in stage
LIST @pbi_stage;

-- Simple aggregation
SELECT Year, COUNT(*) AS record_count
FROM PBI_Dataset
GROUP BY Year
ORDER BY Year;

-- Create a working copy of the dataset
CREATE TABLE agriculture AS
SELECT * FROM PBI_Dataset;

-- Example transformations
-- Increase rainfall by 10%
UPDATE agriculture
SET Rainfall = 1.1 * Rainfall;

-- Decrease area by 10%
UPDATE agriculture
SET Area = 0.9 * Area;

-- Add Year_Group column and classify records
ALTER TABLE agriculture ADD Year_Group STRING;

UPDATE agriculture SET Year_Group = 'Y1' WHERE Year BETWEEN 2004 AND 2009;
UPDATE agriculture SET Year_Group = 'Y2' WHERE Year BETWEEN 2010 AND 2015;
UPDATE agriculture SET Year_Group = 'Y3' WHERE Year BETWEEN 2016 AND 2019;

-- Add Rainfall_Group column and classify records
ALTER TABLE agriculture ADD Rainfall_Group STRING;

UPDATE agriculture SET Rainfall_Group = 'Low' WHERE Rainfall >= 255 AND Rainfall < 1200;
UPDATE agriculture SET Rainfall_Group = 'Medium' WHERE Rainfall >= 1200 AND Rainfall <= 2800;
UPDATE agriculture SET Rainfall_Group = 'High' WHERE Rainfall >= 2800 AND Rainfall <= 4103;

-- Final check
SELECT * FROM agriculture;
