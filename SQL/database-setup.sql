/* ==========================================================
   Database Schema for Airline Sentiment Analysis
   ========================================================== */

CREATE TABLE preprocessed_airline_reviews4 (
    ReviewID INT IDENTITY(1,1) PRIMARY KEY,
    AirlineName NVARCHAR(100) NULL,
    Rating10 INT NULL,
    Title NVARCHAR(255) NULL,
    ReviewerName NVARCHAR(255) NULL,
    ReviewDate DATE NULL,
    ReviewText NVARCHAR(MAX) NOT NULL,
    Recommended BIT NULL,
    positive_aspects NVARCHAR(MAX) NULL,
    negative_aspects NVARCHAR(MAX) NULL,
    SentimentLabel NVARCHAR(50) NULL,
    SentPositive DECIMAL(5,4) NULL,
    SentNeutral DECIMAL(5,4) NULL,
    SentNegative DECIMAL(5,4) NULL,
    SentimentUpdatedAt DATETIME2 NULL,
    NaturalKeyHash NVARCHAR(256) NULL
);

GO

/* ==========================================================
   Monitoring Queries
   ========================================================== */

-- Check processing progress
SELECT 
    COUNT(*) as TotalReviews,
    SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) as ProcessedReviews,
    SUM(CASE WHEN positive_aspects IS NULL THEN 1 ELSE 0 END) as RemainingReviews,
    CAST(SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as PercentComplete
FROM preprocessed_airline_reviews4;

-- Identify unprocessed records
SELECT ReviewID, AirlineName, ReviewText
FROM preprocessed_airline_reviews4
WHERE positive_aspects IS NULL 
  AND negative_aspects IS NULL 
  AND SentimentLabel IS NULL
ORDER BY ReviewID;

-- Track range of processed reviews
SELECT 
    MIN(ReviewID) as FirstProcessed,
    MAX(ReviewID) as LastProcessed,
    COUNT(*) as TotalProcessed
FROM preprocessed_airline_reviews4
WHERE positive_aspects IS NOT NULL;

GO

/* ==========================================================
   Sample Data Inserts (for quick testing)
   ========================================================== */

INSERT INTO preprocessed_airline_reviews4 
(AirlineName, Rating10, Title, ReviewerName, ReviewDate, ReviewText, Recommended)
VALUES
('AirIndia', 10, 'one way my ife was not working', 'Rajiv Jaggi', '2024-04-11',
 'trip verified i travelled with my wife on air india from delhi to newark via mumbai i must say that the service from crew members were flawless...', 1),

('Vistara', 10, 'scores over other airlines', 'Vikaas Kalantri', '2016-06-15',
 'mumbai to delhi and i feel that vistara is next in class the seat space service food and staff this airline scores over other airlines in india...', 1);
