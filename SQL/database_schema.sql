-- Database Schema for Airline Sentiment Analysis
-- Table: preprocessed_airline_reviews4

CREATE TABLE preprocessed_airline_reviews4 (
    airline_name NVARCHAR(255),
    rating TINYINT,
    title NVARCHAR(MAX),
    reviewer_name NVARCHAR(255),
    review_date DATE,
    review_text NVARCHAR(MAX),
    recommended BIT,
    ReviewID UNIQUEIDENTIFIER PRIMARY KEY,
    sentiment_score FLOAT,
    sentiment_label NVARCHAR(50),
    positive_score FLOAT,
    neutral_score FLOAT,
    negative_score FLOAT,
    analyzed_date DATETIME2(7),
    ai_confidence FLOAT,
    positive_aspects NVARCHAR(MAX),
    negative_aspects NVARCHAR(MAX),
    is_mixed_review BIT
);

-- Stored Procedure for updating review aspects
CREATE PROCEDURE [dbo].[UpdateReviewAspects]
    @ReviewID UNIQUEIDENTIFIER,
    @PositiveAspects NVARCHAR(MAX),
    @NegativeAspects NVARCHAR(MAX),
    @IsMixedReview BIT
AS
BEGIN
    UPDATE preprocessed_airline_reviews4
    SET 
        positive_aspects = @PositiveAspects,
        negative_aspects = @NegativeAspects,
        is_mixed_review = @IsMixedReview,
        analyzed_date = GETDATE()
    WHERE ReviewID = @ReviewID;
END;