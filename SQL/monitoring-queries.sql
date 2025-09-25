/*
    Monitoring Queries for Airline Sentiment Analysis Project
    ---------------------------------------------------------
    These queries help track pipeline progress and validate
    sentiment analysis updates in the SQL database.
*/

/* 1. Overall Processing Progress */
SELECT 
    COUNT(*) AS TotalReviews,
    SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) AS ProcessedReviews,
    SUM(CASE WHEN positive_aspects IS NULL THEN 1 ELSE 0 END) AS RemainingReviews,
    CAST(SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS PercentComplete
FROM preprocessed_airline_reviews4;


/* 2. Identify Unprocessed Records */
SELECT TOP 20 
    ReviewID,
    AirlineName,
    Title,
    ReviewDate
FROM preprocessed_airline_reviews4
WHERE positive_aspects IS NULL
  AND negative_aspects IS NULL
  AND SentimentLabel IS NULL
ORDER BY ReviewID;


/* 3. Track First & Last Processed Review IDs */
SELECT 
    MIN(ReviewID) AS FirstProcessedID,
    MAX(ReviewID) AS LastProcessedID,
    COUNT(*) AS TotalProcessed
FROM preprocessed_airline_reviews4
WHERE positive_aspects IS NOT NULL;


/* 4. Recently Processed Reviews */
SELECT TOP 10 
    ReviewID,
    AirlineName,
    SentimentLabel,
    SentPositive,
    SentNeutral,
    SentNegative,
    SentimentUpdatedAt
FROM preprocessed_airline_reviews4
WHERE SentimentLabel IS NOT NULL
ORDER BY SentimentUpdatedAt DESC;
