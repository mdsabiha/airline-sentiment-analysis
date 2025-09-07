# Airline Sentiment Analysis Pipeline

## Overview

This project implements an automated sentiment analysis pipeline for airline customer reviews using Azure Data Factory and Azure Text Analytics. The system processes 2,210 airline reviews to extract positive aspects, negative aspects, and determine if reviews contain mixed sentiment.

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
    review_text NVARCHAR(MAX),
    positive_aspects NVARCHAR(MAX),
    negative_aspects NVARCHAR(MAX),
    is_mixed_review BIT
);
```

## Key Features

- **Automated Processing**: Trigger-based pipeline execution for hands-free operation
- **Opinion Mining**: Extracts specific positive and negative aspects from reviews
- **Mixed Sentiment Detection**: Identifies reviews containing both positive and negative sentiments
- **Batch Processing**: Processes reviews in batches of 5 to respect Azure API rate limits
- **Cost Optimization**: Designed to operate within Azure free tier limitations

## Cost Structure

### Azure Text Analytics Service
- **Free Tier Allocation**: 5,000 text records per month
- **Project Requirements**: 2,210 reviews
- **Associated Cost**: Free (within allocation limits)

### Azure Data Factory Service
- **Free Tier Allocation**: 5 pipeline runs per month
- **Project Requirements**: Approximately 442 pipeline runs
- **Associated Cost**: $0.44 for additional runs beyond free tier

### Total Project Investment: $0.44

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
    review_text NVARCHAR(MAX) NOT NULL,
    positive_aspects NVARCHAR(MAX) NULL,
    negative_aspects NVARCHAR(MAX) NULL,
    is_mixed_review BIT NULL
);

-- Data import process
-- Use BULK INSERT or Azure Data Factory for initial data loading
```

### Azure Text Analytics Setup
1. Provision Azure Text Analytics cognitive service
2. Record the service endpoint URL and access key
3. Verify Opinion Mining feature is enabled

### Data Factory Pipeline Implementation

#### Pipeline Name: OpinionMiningPipeline

**Pipeline Activities:**
1. **GetUnprocessedReviews** - Lookup Activity
2. **ProcessReviews** - ForEach Loop Activity
3. **CallTextAnalytics** - Web Activity
4. **UpdateDatabase** - Stored Procedure Activity

#### Data Lookup Configuration
```sql
SELECT TOP 5 ReviewID, review_text 
FROM dbo.preprocessed_airline_reviews4 
WHERE positive_aspects IS NULL 
  AND negative_aspects IS NULL 
  AND is_mixed_review IS NULL;
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
      "text": "@{item().review_text}",
      "language": "en"
    }
  ],
  "opinionMining": true
}
```

### Automation Configuration

#### Trigger Specifications
```
Trigger Name: AutoProcess
Trigger Type: ScheduleTrigger
Execution Frequency: Every 2 minutes
Start Date: Current date
Operational Status: Started
```

## Pipeline Execution Flow

1. **Data Retrieval**: Lookup activity identifies 5 unprocessed reviews
2. **Iterative Processing**: ForEach loop handles individual review processing
3. **API Integration**: Web activity calls Azure Text Analytics service
4. **Data Transformation**: System extracts opinions and sentiment classifications
5. **Data Persistence**: Results are stored back to SQL database

## Monitoring and Analytics

### Pipeline Monitoring
- Access the **Monitor** section in Azure Data Factory
- Review **Pipeline runs** for execution status tracking
- Monitor **Trigger runs** for automation health

### Progress Monitoring Query
```sql
SELECT 
    COUNT(*) as TotalReviews,
    SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) as ProcessedReviews,
    SUM(CASE WHEN positive_aspects IS NULL THEN 1 ELSE 0 END) as RemainingReviews,
    CAST(SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as PercentComplete
FROM preprocessed_airline_reviews4;
```

## Output Data Structure

### Positive Aspects Format
```json
[
  {"aspect": "service", "sentiment": "positive"},
  {"aspect": "food", "sentiment": "positive"}
]
```

### Negative Aspects Format
```json
[
  {"aspect": "delay", "sentiment": "negative"},
  {"aspect": "seats", "sentiment": "negative"}
]
```

### Mixed Review Classification
- **Value 1**: Review contains both positive and negative sentiments
- **Value 0**: Review is predominantly positive or negative

## Sample Output

| ReviewID | Positive Aspects | Negative Aspects | Mixed Review |
|----------|------------------|------------------|--------------|
| 1 | "friendly staff, good food" | "delayed flight" | 1 |
| 2 | "comfortable seats" | NULL | 0 |
| 3 | NULL | "poor service, bad food" | 0 |

## Troubleshooting Guide

### Common Issues and Resolutions

**Pipeline Execution Problems**
- Verify trigger status (Started versus Stopped)
- Confirm all changes have been published
- Check that start date is not set to future date

**API Integration Errors**
- Validate Text Analytics endpoint URL and subscription key
- Review API rate limits for free tier accounts
- Verify request payload format compliance

**Database Connectivity Issues**
- Test connection string validity
- Review Azure SQL firewall configuration
- Validate database authentication credentials

### Diagnostic Queries

```sql
-- Identify unprocessed records
SELECT ReviewID, review_text 
FROM preprocessed_airline_reviews4 
WHERE positive_aspects IS NULL 
  AND negative_aspects IS NULL 
  AND is_mixed_review IS NULL
ORDER BY ReviewID;

-- Track processing progress
SELECT 
    MIN(ReviewID) as FirstProcessed,
    MAX(ReviewID) as LastProcessed,
    COUNT(*) as TotalProcessed
FROM preprocessed_airline_reviews4 
WHERE positive_aspects IS NOT NULL;
```

## Performance Specifications

### Current Configuration
- **Batch Processing Size**: 5 reviews per execution
- **Execution Frequency**: Every 2 minutes
- **Total Processing Duration**: Approximately 15 hours for complete dataset

### Performance Optimization Options
1. Increase batch size within API rate limits
2. Implement parallel processing (requires upgraded pricing tier)
3. Develop custom batch logic based on review text length

## Future Development Roadmap

- Real-time sentiment analysis dashboard implementation
- Email notification system for processing completion
- Enhanced sentiment scoring algorithms
- Multi-language processing capabilities
- Automated reporting and analytics generation
- Power BI dashboard integration
- Historical sentiment trend analysis
- Advanced keyword and phrase extraction
- Comparative sentiment analysis across multiple airlines
- Machine learning model training for custom sentiment classification

## Technical Specifications

### System Requirements
- Azure subscription with sufficient credits
- .NET Framework compatibility for Data Factory
- SQL Server compatibility level 130 or higher
- Modern web browser for Azure portal access

### API Dependencies
- Azure Text Analytics API v3.1 or higher
- Opinion Mining feature availability
- Sufficient API quota allocation

### Data Storage Requirements
- Estimated storage: 50MB for complete dataset
- Transaction log space for frequent updates
- Backup storage recommendations: 100MB

## Documentation and Resources

### Official Microsoft Documentation
- [Azure Data Factory Documentation](https://docs.microsoft.com/en-us/azure/data-factory/)
- [Azure Text Analytics API Reference](https://docs.microsoft.com/en-us/azure/cognitive-services/text-analytics/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/)

### Best Practices
- Regular monitoring of API usage and costs
- Implementation of error handling and retry logic
- Backup strategies for processed data
- Security considerations for API keys and connection strings

## License

This project is distributed under the MIT License. See the LICENSE file for complete terms and conditions.

## Contributing

We welcome contributions to this project. Please follow these guidelines:

1. Fork the repository to your GitHub account
2. Create a feature branch using descriptive naming (`git checkout -b feature/EnhancedSentimentAnalysis`)
3. Commit changes with clear, descriptive messages (`git commit -m 'Add support for multi-language sentiment analysis'`)
4. Push changes to your feature branch (`git push origin feature/EnhancedSentimentAnalysis`)
5. Submit a Pull Request with detailed description of changes

### Contribution Guidelines
- Follow existing code style and conventions
- Include appropriate documentation for new features
- Add unit tests for new functionality where applicable
- Update README documentation for significant changes

## Support and Contact

For technical support and questions:
- Submit issues through the GitHub repository issue tracker
- Consult Azure Data Factory official documentation
- Reference Azure Text Analytics API documentation and troubleshooting guides
- Review Azure community forums for common solutions

## Repository Structure

```
airline-sentiment-analysis/
├── README.md
├── LICENSE
├── .gitignore
├── pipeline/
│   ├── OpinionMiningPipeline.json
│   └── trigger-configuration.json
├── sql/
│   ├── database-schema.sql
│   ├── monitoring-queries.sql
│   └── sample-data.sql
├── documentation/
│   ├── setup-guide.md
│   ├── troubleshooting.md
│   └── api-reference.md
└── examples/
    ├── sample-output.json
    └── test-data.csv
```

---

**Project developed using Azure Data Factory and Azure Text Analytics cognitive services**
