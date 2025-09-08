-- Monitoring Queries for Airline Sentiment Analysis Pipeline

-- 1. Overall Progress Tracking
SELECT 
    COUNT(*) as TotalReviews,
    SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) as ProcessedReviews,
    SUM(CASE WHEN positive_aspects IS NULL THEN 1 ELSE 0 END) as RemainingReviews,
    CAST(SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as PercentComplete
FROM preprocessed_airline_reviews4;

-- 2. Recent Processing Activity
SELECT TOP 20
    ReviewID,
    LEFT(review_text, 100) + '...' as ReviewPreview,
    sentiment_label,
    positive_aspects,
    negative_aspects,
    is_mixed_review,
    analyzed_date
FROM preprocessed_airline_reviews4 
WHERE positive_aspects IS NOT NULL
ORDER BY analyzed_date DESC;

-- 3. Sentiment Distribution Analysis
SELECT 
    sentiment_label,
    COUNT(*) as ReviewCount,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM preprocessed_airline_reviews4 WHERE sentiment_label IS NOT NULL) AS DECIMAL(5,2)) as Percentage,
    AVG(sentiment_score) as AvgSentimentScore
FROM preprocessed_airline_reviews4 
WHERE sentiment_label IS NOT NULL
GROUP BY sentiment_label
ORDER BY ReviewCount DESC;

-- 4. Mixed Review Analysis
SELECT 
    is_mixed_review,
    COUNT(*) as ReviewCount,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM preprocessed_airline_reviews4 WHERE is_mixed_review IS NOT NULL) AS DECIMAL(5,2)) as Percentage
FROM preprocessed_airline_reviews4 
WHERE is_mixed_review IS NOT NULL
GROUP BY is_mixed_review;

-- 5. Airline Performance Summary
SELECT 
    airline_name,
    COUNT(*) as TotalReviews,
    SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) as ProcessedReviews,
    AVG(CASE WHEN sentiment_score IS NOT NULL THEN sentiment_score END) as AvgSentimentScore,
    AVG(CASE WHEN rating IS NOT NULL THEN CAST(rating AS FLOAT) END) as AvgRating
FROM preprocessed_airline_reviews4
GROUP BY airline_name
ORDER BY AvgSentimentScore DESC;

-- 6. Processing Performance by Date
SELECT 
    CAST(analyzed_date AS DATE) as ProcessingDate,
    COUNT(*) as ReviewsProcessed,
    AVG(sentiment_score) as AvgSentimentScore
FROM preprocessed_airline_reviews4 
WHERE analyzed_date IS NOT NULL
GROUP BY CAST(analyzed_date AS DATE)
ORDER BY ProcessingDate DESC;

-- 7. Find Unprocessed Reviews (for troubleshooting)
SELECT TOP 10
    ReviewID,
    LEFT(review_text, 150) + '...' as ReviewPreview,
    airline_name,
    review_date
FROM preprocessed_airline_reviews4 
WHERE positive_aspects IS NULL 
  AND negative_aspects IS NULL 
  AND is_mixed_review IS NULL
ORDER BY review_date DESC;

-- 8. Error Detection - Reviews with incomplete processing
SELECT 
    'Partial Processing Issues' as IssueType,
    COUNT(*) as AffectedReviews
FROM preprocessed_airline_reviews4 
WHERE (positive_aspects IS NOT NULL AND negative_aspects IS NULL)
   OR (positive_aspects IS NULL AND negative_aspects IS NOT NULL)
   OR (is_mixed_review IS NULL AND (positive_aspects IS NOT NULL OR negative_aspects IS NOT NULL));

-- 9. Top Positive and Negative Aspects (sample analysis)
-- Note: This would require parsing the JSON aspects - simplified version shown
SELECT 
    'Positive Aspects Analysis' as AnalysisType,
    COUNT(CASE WHEN positive_aspects IS NOT NULL AND positive_aspects != '' THEN 1 END) as ReviewsWithPositiveAspects,
    COUNT(CASE WHEN negative_aspects IS NOT NULL AND negative_aspects != '' THEN 1 END) as ReviewsWithNegativeAspects
FROM preprocessed_airline_reviews4;

-- 10. Daily Processing Rate (for automation monitoring)
SELECT 
    DATEPART(HOUR, analyzed_date) as ProcessingHour,
    COUNT(*) as ReviewsProcessed
FROM preprocessed_airline_reviews4 
WHERE analyzed_date >= DATEADD(DAY, -1, GETDATE())
GROUP BY DATEPART(HOUR, analyzed_date)
ORDER BY ProcessingHour;