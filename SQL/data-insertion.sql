/* ==========================================================
   Bulk Insert Script for Airline Reviews
   ========================================================== */

/* 
   Prerequisites:
   1. Your dataset (airline_reviews.csv) is uploaded to Azure Blob Storage
   2. You have created an external data source in Azure SQL that points to your Blob container
      Example:
      CREATE DATABASE SCOPED CREDENTIAL MyAzureBlobCredential
      WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
           SECRET = '<Your-SAS-Token>';

      CREATE EXTERNAL DATA SOURCE MyBlobStorage
      WITH ( TYPE = BLOB_STORAGE,
             LOCATION = 'https://<yourstorageaccount>.blob.core.windows.net/<yourcontainer>',
             CREDENTIAL = MyAzureBlobCredential );
*/

/* ==========================================================
   Create staging table (optional, for raw import)
   ========================================================== */

CREATE TABLE AirlineReviewsStaging (
    Airline NVARCHAR(100),
    Title NVARCHAR(400),
    ReviewText NVARCHAR(MAX),
    Rating INT,
    Recommended BIT,
    ReviewDate DATE,
    WordCount INT NULL,
    ExclamationCount INT NULL,
    Year INT NULL,
    Month INT NULL
);

GO

/* ==========================================================
   Bulk Insert into staging table
   ========================================================== */

BULK INSERT AirlineReviewsStaging
FROM 'airline_reviews.csv'
WITH (
    DATA_SOURCE = 'MyBlobStorage',
    FORMAT = 'CSV',
    FIRSTROW = 2,                -- Skip header row
    FIELDTERMINATOR = ',',       -- Comma-separated
    ROWTERMINATOR = '0x0a',      -- New line
    TABLOCK
);

GO

/* ==========================================================
   Migrate to Main Table
   ========================================================== */

INSERT INTO preprocessed_airline_reviews4 
(AirlineName, Title, ReviewText, Rating10, Recommended, ReviewDate, NaturalKeyHash)
SELECT 
    Airline,
    Title,
    ReviewText,
    Rating,
    Recommended,
    ReviewDate,
    CONVERT(VARCHAR(256), HASHBYTES('SHA2_256', Airline + Title + ISNULL(ReviewText, '')), 1)
FROM AirlineReviewsStaging;

GO

/* ==========================================================
   Cleanup
   ========================================================== */
TRUNCATE TABLE AirlineReviewsStaging;   -- Keep staging for future loads (optional)
-- DROP TABLE AirlineReviewsStaging;    -- Uncomment if you don’t need staging
