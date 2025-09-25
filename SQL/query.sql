USE [airline_sentiment_db];
GO

IF OBJECT_ID('dbo.airline_reviews','U') IS NULL
BEGIN
    CREATE TABLE dbo.airline_reviews (
        ReviewID            INT IDENTITY(1,1) PRIMARY KEY,

        -- from your preprocessed CSV
        AirlineName         NVARCHAR(200)     NOT NULL,
        Rating10            TINYINT           NULL,
        Title               NVARCHAR(400)     NULL,
        ReviewerName        NVARCHAR(200)     NULL,
        ReviewDate          DATE              NULL,
        ReviewText          NVARCHAR(MAX)     NOT NULL,
        Recommended         BIT               NULL,

        -- empty analysis columns (to be filled later)
        positive_aspects    NVARCHAR(MAX)     NULL,
        negative_aspects    NVARCHAR(MAX)     NULL,
        is_mixed_review     BIT               NULL,
        SentimentLabel      VARCHAR(8)        NULL,   -- 'positive' | 'neutral' | 'negative'
        SentPositive        DECIMAL(5,4)      NULL,
        SentNeutral         DECIMAL(5,4)      NULL,
        SentNegative        DECIMAL(5,4)      NULL,
        SentimentUpdatedAt  DATETIME2         NULL
    );
END
GO
