CREATE OR ALTER PROCEDURE [dbo].[UpdateCompleteReviewAnalysis]
(
    @ReviewID INT,
    @SentimentResponse NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @SentimentLabel VARCHAR(8),
        @PositiveScore DECIMAL(6,4),
        @NeutralScore DECIMAL(6,4),
        @NegativeScore DECIMAL(6,4),
        @PositiveAspects NVARCHAR(MAX) = '',
        @NegativeAspects NVARCHAR(MAX) = '',
        @IsMixedReview BIT = 0,
        @KeyPhrases NVARCHAR(MAX),
        @ReviewText NVARCHAR(MAX);

    BEGIN TRY
        -- Parse basic sentiment
        SELECT
            @SentimentLabel = JSON_VALUE(@SentimentResponse, '$.documents[0].sentiment'),
            @PositiveScore  = TRY_CAST(JSON_VALUE(@SentimentResponse, '$.documents[0].confidenceScores.positive') AS DECIMAL(6,4)),
            @NeutralScore   = TRY_CAST(JSON_VALUE(@SentimentResponse, '$.documents[0].confidenceScores.neutral') AS DECIMAL(6,4)),
            @NegativeScore  = TRY_CAST(JSON_VALUE(@SentimentResponse, '$.documents[0].confidenceScores.negative') AS DECIMAL(6,4));

        -- Set defaults
        SET @PositiveScore = ISNULL(@PositiveScore, 0.0);
        SET @NeutralScore = ISNULL(@NeutralScore, 0.0);
        SET @NegativeScore = ISNULL(@NegativeScore, 0.0);

        -- Get review text
        SELECT @ReviewText = ReviewText FROM airline_reviews WHERE ReviewID = @ReviewID;

        -- ENHANCED ASPECT EXTRACTION
        DECLARE @TempAspects TABLE (AspectType VARCHAR(10), AspectText NVARCHAR(100));

        -- Positive aspects
        IF @ReviewText LIKE '%crew%' AND (@ReviewText LIKE '%good%' OR @ReviewText LIKE '%great%' OR @ReviewText LIKE '%welcoming%' OR @ReviewText LIKE '%polite%' OR @ReviewText LIKE '%professional%' OR @ReviewText LIKE '%amazing%' OR @ReviewText LIKE '%thank%' OR @ReviewText LIKE '%appreciate%')
            INSERT INTO @TempAspects VALUES ('positive', 'Crew service')
        
        IF @ReviewText LIKE '%staff%' AND (@ReviewText LIKE '%helpful%' OR @ReviewText LIKE '%support%' OR @ReviewText LIKE '%knowledgeable%' OR @ReviewText LIKE '%polite%' OR @ReviewText LIKE '%professional%')
            INSERT INTO @TempAspects VALUES ('positive', 'Staff assistance')
        
        IF @ReviewText LIKE '%boarding%' AND (@ReviewText LIKE '%smooth%' OR @ReviewText LIKE '%easy%' OR @ReviewText LIKE '%fast%' OR @ReviewText LIKE '%good%')
            INSERT INTO @TempAspects VALUES ('positive', 'Boarding process')
        
        IF @ReviewText LIKE '%flight%' AND (@ReviewText LIKE '%comfortable%' OR @ReviewText LIKE '%smooth%' OR @ReviewText LIKE '%enjoyable%')
            INSERT INTO @TempAspects VALUES ('positive', 'Flight comfort')
        
        IF @ReviewText LIKE '%luggage%' AND (@ReviewText LIKE '%good%' OR @ReviewText LIKE '%fast%' OR @ReviewText LIKE '%smooth%' OR @ReviewText LIKE '%swift%')
            INSERT INTO @TempAspects VALUES ('positive', 'Luggage handling')
        
        IF @ReviewText LIKE '%check-in%' OR @ReviewText LIKE '%check in%' AND (@ReviewText LIKE '%good%' OR @ReviewText LIKE '%smooth%' OR @ReviewText LIKE '%easy%')
            INSERT INTO @TempAspects VALUES ('positive', 'Check-in experience')

        IF @ReviewText LIKE '%announcement%' AND (@ReviewText LIKE '%good%' OR @ReviewText LIKE '%clear%' OR @ReviewText LIKE '%amazing%')
            INSERT INTO @TempAspects VALUES ('positive', 'Announcements quality')

        IF @ReviewText LIKE '%supervisor%' OR @ReviewText LIKE '%manager%' AND (@ReviewText LIKE '%good%' OR @ReviewText LIKE '%helpful%' OR @ReviewText LIKE '%professional%')
            INSERT INTO @TempAspects VALUES ('positive', 'Management quality')

        -- Negative aspects
        IF @ReviewText LIKE '%staff%' AND (@ReviewText LIKE '%rude%' OR @ReviewText LIKE '%bad%' OR @ReviewText LIKE '%angry%' OR @ReviewText LIKE '%unbothered%' OR @ReviewText LIKE '%frustrated%' OR @ReviewText LIKE '%not trained%')
            INSERT INTO @TempAspects VALUES ('negative', 'Staff behavior')
        
        IF @ReviewText LIKE '%delay%' OR @ReviewText LIKE '%late%' OR @ReviewText LIKE '%wait%'
            INSERT INTO @TempAspects VALUES ('negative', 'Flight delays')
        
        IF @ReviewText LIKE '%boarding%' AND (@ReviewText LIKE '%problem%' OR @ReviewText LIKE '%issue%' OR @ReviewText LIKE '%denied%' OR @ReviewText LIKE '%not allow%')
            INSERT INTO @TempAspects VALUES ('negative', 'Boarding issues')
        
        IF @ReviewText LIKE '%seat%' AND (@ReviewText LIKE '%tight%' OR @ReviewText LIKE '%small%' OR @ReviewText LIKE '%uncomfortable%')
            INSERT INTO @TempAspects VALUES ('negative', 'Seat comfort')
        
        IF @ReviewText LIKE '%worst%' OR @ReviewText LIKE '%hate%' OR @ReviewText LIKE '%waste%' OR @ReviewText LIKE '%not recommend%'
            INSERT INTO @TempAspects VALUES ('negative', 'Overall service quality')

        IF @ReviewText LIKE '%recommend%' AND (@ReviewText LIKE '%not%' OR @ReviewText LIKE '%never%' OR @ReviewText LIKE '%wont%')
            INSERT INTO @TempAspects VALUES ('negative', 'Not recommended')

        IF @ReviewText LIKE '%waste%' OR @ReviewText LIKE '%worthless%' OR @ReviewText LIKE '%useless%'
            INSERT INTO @TempAspects VALUES ('negative', 'Poor value')

        -- Aggregate aspects
        SELECT @PositiveAspects = STRING_AGG(AspectText, '; ')
        FROM @TempAspects WHERE AspectType = 'positive';
        
        SELECT @NegativeAspects = STRING_AGG(AspectText, '; ')
        FROM @TempAspects WHERE AspectType = 'negative';

        -- Fallback if no aspects detected
        IF LEN(ISNULL(@PositiveAspects, '')) = 0 AND @PositiveScore > 0.5
            SET @PositiveAspects = 'Positive service experience'
        
        IF LEN(ISNULL(@NegativeAspects, '')) = 0 AND @NegativeScore > 0.5
            SET @NegativeAspects = 'Service issues'

        -- Mixed review
        SET @IsMixedReview = CASE 
            WHEN @PositiveScore > 0.3 AND @NegativeScore > 0.3 THEN 1 
            ELSE 0 END;

        -- Key phrases
        SET @KeyPhrases = (
            SELECT STRING_AGG(phrase.value, ', ')
            FROM OPENJSON(@SentimentResponse, '$.documents[0].keyPhrases') AS phrase
        );

        -- Update the table
        UPDATE airline_reviews
        SET
            SentimentLabel = @SentimentLabel,
            SentPositive = @PositiveScore,
            SentNeutral = @NeutralScore,
            SentNegative = @NegativeScore,
            positive_aspects = NULLIF(@PositiveAspects, ''),
            negative_aspects = NULLIF(@NegativeAspects, ''),
            is_mixed_review = @IsMixedReview,
            KeyPhrases = @KeyPhrases,
            SentimentUpdatedAt = SYSUTCDATETIME()
        WHERE ReviewID = @ReviewID;

        PRINT 'Updated ReviewID: ' + CAST(@ReviewID AS VARCHAR(10));

    END TRY
    BEGIN CATCH
        PRINT 'Error for ReviewID ' + CAST(@ReviewID AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
    END CATCH
END;
GO