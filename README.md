# Airline Sentiment Analysis Pipeline

## Overview

This project implements an automated sentiment analysis pipeline for airline customer reviews using **Azure Data Factory** and **Azure Text Analytics**.  
The system processes **2,210 airline reviews** to extract **positive aspects**, **negative aspects**, assign an overall **sentiment label**, and provide confidence scores.

## Architecture

The pipeline follows a straightforward ETL (Extract, Transform, Load) architecture:

```
Raw Reviews → Azure Data Factory → Azure Text Analytics → Processed Data → SQL Database
```

### Core Components
- **Azure Data Factory**: Orchestrates the entire data pipeline
- **Azure Text Analytics**: Performs sentiment analysis and opinion mining
- **Azure SQL Database**: Stores both preprocessed and analyzed data
- **Visualization Tools**: Power BI or Tableau integration (optional)

## Dataset Information

- **Source**: Airline customer reviews dataset
- **Total Records**: 2,210 reviews
- **Format**: CSV format with review text and associated metadata
- **Primary Table**: `preprocessed_airline_reviews4`

### Database Schema
```sql
CREATE TABLE preprocessed_airline_reviews4 (
    ReviewID INT PRIMARY KEY,
    AirlineName NVARCHAR(100),
    Rating10 INT,
    Title NVARCHAR(500),
    ReviewerName NVARCHAR(200),
    ReviewDate DATE,
    ReviewText NVARCHAR(MAX),
    Recommended BIT,
    positive_aspects NVARCHAR(MAX),
    negative_aspects NVARCHAR(MAX),
    SentimentLabel NVARCHAR(20),
    SentPositive DECIMAL(5,4),
    SentNeutral DECIMAL(5,4),
    SentNegative DECIMAL(5,4),
    SentimentUpdatedAt DATETIME2,
    NaturalKeyHash NVARCHAR(200)
);
```
### Data Loading (Bulk Insert via Blob Storage)

The dataset (airline_reviews.csv) containing 2,210 airline reviews was inserted into Azure SQL Database using Azure Blob Storage + BULK INSERT:
BULK INSERT AirlineReviewsStaging
```
FROM 'airline_reviews.csv'
WITH (
    DATA_SOURCE = 'MyBlobStorage',
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
```
```
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
```

## Key Features

- **Automated Processing**: Trigger-based pipeline execution for hands-free operation  
- **Opinion Mining**: Extracts specific positive and negative aspects from reviews  
- **Sentiment Classification**: Identifies positive, negative, and neutral sentiment scores  
- **Batch Processing**: Processes reviews in batches of 5 to respect Azure API rate limits  
- **Cost Optimization**: Designed to operate within Azure free tier limitations  

## Cost Structure

### Azure Text Analytics Service
- **Free Tier Allocation**: 5,000 text records per month  
- **Project Requirements**: 2,210 reviews  
- **Associated Cost**: Free (within allocation limits)  

### Azure Data Factory Service
- **Free Tier Allocation**: 5 pipeline runs per month  
- **Project Requirements**: ~442 pipeline runs  
- **Associated Cost**: ~$0.44 for additional runs beyond free tier  

### **Total Project Investment: $0.44**

## Installation and Setup

### System Requirements
- Active Azure subscription (Student or Free Trial account)  
- Azure Data Factory instance  
- Azure Text Analytics cognitive service  
- Azure SQL Database  

### Database Configuration

```sql
-- Create primary table structure
CREATE TABLE preprocessed_airline_reviews4 (
    ReviewID INT IDENTITY(1,1) PRIMARY KEY,
    AirlineName NVARCHAR(100),
    Rating10 INT,
    Title NVARCHAR(500),
    ReviewerName NVARCHAR(200),
    ReviewDate DATE,
    ReviewText NVARCHAR(MAX),
    Recommended BIT,
    positive_aspects NVARCHAR(MAX),
    negative_aspects NVARCHAR(MAX),
    SentimentLabel NVARCHAR(20),
    SentPositive DECIMAL(5,4),
    SentNeutral DECIMAL(5,4),
    SentNegative DECIMAL(5,4),
    SentimentUpdatedAt DATETIME2,
    NaturalKeyHash NVARCHAR(200)
);
```

---

### Azure Text Analytics Setup
1. Provision Azure Text Analytics cognitive service  
2. Record the service endpoint URL and access key  
3. Verify Opinion Mining feature is enabled  

### Data Factory Pipeline Implementation

#### Pipeline Name: `OpinionMiningPipeline`

**Pipeline Activities:**
1. **GetUnprocessedReviews** – Lookup Activity  
2. **ProcessReviews** – ForEach Loop Activity  
3. **CallTextAnalytics** – Web Activity  
4. **UpdateDatabase** – Stored Procedure Activity  

#### Data Lookup Configuration
```sql
SELECT TOP 5 ReviewID, ReviewText
FROM dbo.preprocessed_airline_reviews4
WHERE positive_aspects IS NULL
  AND negative_aspects IS NULL
  AND SentimentLabel IS NULL;
```

#### Text Analytics API Integration
- **Endpoint URL**: `https://[your-resource].cognitiveservices.azure.com/text/analytics/v3.1/sentiment`  
- **HTTP Method**: POST  
- **Required Headers**:  
  - `Ocp-Apim-Subscription-Key`: [Your API Key]  
  - `Content-Type`: application/json  

#### API Request Structure
```json
{
  "documents": [
    {
      "id": "@{item().ReviewID}",
      "text": "@{item().ReviewText}",
      "language": "en"
    }
  ],
  "opinionMining": true
}
```

---

## Pipeline Execution Flow

1. **Data Retrieval** – Lookup fetches 5 unprocessed reviews  
2. **Iterative Processing** – ForEach loop processes each review  
3. **API Integration** – Web activity calls Azure Text Analytics service  
4. **Data Transformation** – Extract opinions and sentiment classifications  
5. **Data Persistence** – Results stored back in SQL database  

---

## Monitoring and Analytics

### Progress Monitoring Query
```sql
SELECT 
    COUNT(*) AS TotalReviews,
    SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) AS ProcessedReviews,
    SUM(CASE WHEN positive_aspects IS NULL THEN 1 ELSE 0 END) AS RemainingReviews,
    CAST(SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS PercentComplete
FROM preprocessed_airline_reviews4;
```

---

## Sample Output

Here’s an example of processed rows:

| ReviewID | AirlineName | Rating10 | Title                          | SentimentLabel | SentPositive | SentNeutral | SentNegative | Positive Aspects          | Negative Aspects     |
|----------|-------------|----------|--------------------------------|----------------|--------------|-------------|--------------|---------------------------|----------------------|
| 191      | AirIndia    | 10       | one way my ife was not working | positive       | 1.0000       | 0.0000      | 0.0000       | Crew service              | NULL                 |
| 190      | AirIndia    | 3        | seat back was in bad state     | negative       | 0.0200       | 0.0000      | 0.9800       | Flight comfort, Announcements quality | Service issues      |
| 189      | AirIndia    | 9        | the flight was quite nice      | positive       | 1.0000       | 0.0000      | 0.0000       | Boarding process, Check-in experience | NULL                 |
| 187      | AirIndia    | 1        | no working entertainment       | negative       | 0.0000       | 0.0000      | 1.0000       | NULL                      | Service issues       |

---

## Troubleshooting Guide

**Pipeline Execution Problems**
- Verify trigger status (Started vs Stopped)  
- Confirm changes are published  
- Check start date isn’t set to future  

**API Errors**
- Validate endpoint URL & subscription key  
- Review API rate limits for free tier  
- Verify JSON request payload format  

**SQL Issues**
- Test connection string  
- Check Azure SQL firewall rules  
- Validate authentication credentials  

---

## Performance Specifications

- **Batch Size**: 5 reviews/run  
- **Frequency**: Every 2 minutes  
- **Total Duration**: ~15 hours for 2,210 reviews  

---

## Future Development Roadmap

- Real-time sentiment dashboard  
- Email notifications after pipeline completion  
- Multi-language sentiment analysis  
- Historical sentiment trends  
- Power BI / Tableau dashboards  

---

## Documentation and Resources

- [Azure Data Factory Docs](https://docs.microsoft.com/en-us/azure/data-factory/)  
- [Azure Text Analytics Docs](https://docs.microsoft.com/en-us/azure/cognitive-services/text-analytics/)  
- [Azure SQL Database Docs](https://docs.microsoft.com/en-us/azure/azure-sql/)  

---

## Repository Structure

```
airline-sentiment-analysis/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── pipeline/
│   ├── OpinionMiningPipeline.json
│   └── trigger-configuration.json
│
├── sql/
│   ├── raw_schema.sql
│   ├── processed_schema.sql
│   ├── sentiment_summary.sql
│   ├── monitoring-queries.sql
│   └── data-validation.sql
│
├── results/
│   └── airline_reviews_processed_full.csv
│
├── reports/
│   └── Airline_Reviews_Data_Report.docx
│
├── images/
│   ├── adf_pipeline.png
│   ├── adf_runs.png
│   └── sql_results.png
│
├── documentation/
    ├── setup-guide.md
    ├── troubleshooting.md
    └── api-reference.md

```

---

**Project developed using Azure Data Factory and Azure Text Analytics cognitive services**
