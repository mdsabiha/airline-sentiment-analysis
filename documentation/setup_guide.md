# Setup Guide - Airline Sentiment Analysis Pipeline

## Prerequisites

### Azure Services Required
- Azure Data Factory
- Azure Text Analytics (Cognitive Services)
- Azure SQL Database
- Active Azure subscription (Student/Free Trial recommended)

### Access Requirements
- Azure portal access
- Database administration permissions
- Resource creation permissions in Azure subscription

## Step-by-Step Setup

### Phase 1: Azure Resource Creation

#### 1.1 Create Resource Group
```bash
# Using Azure CLI (optional)
az group create --name airline-sentiment-rg --location eastus
```

#### 1.2 Create Azure SQL Database
1. Navigate to Azure Portal → Create Resource → SQL Database
2. Configure basic settings:
   - Database name: `ai_indian_airline_sentiment`
   - Server: Create new or use existing
   - Compute + storage: Basic (5 DTU minimum)
3. Configure networking to allow Azure services access
4. Create database

#### 1.3 Create Text Analytics Service
1. Navigate to Azure Portal → Create Resource → Text Analytics
2. Configure settings:
   - Resource name: `airlinesentimentanalysis`
   - Pricing tier: F0 (Free)
   - Region: Same as other resources
3. After creation, note the endpoint URL and access keys

#### 1.4 Create Data Factory
1. Navigate to Azure Portal → Create Resource → Data Factory
2. Configure basic settings:
   - Data factory name: `airline-sentiment-factory`
   - Region: Same as other resources
3. Leave Git configuration for later
4. Create resource

### Phase 2: Database Setup

#### 2.1 Create Database Schema
Connect to your Azure SQL Database and execute:

```sql
-- Run the database-schema.sql file
-- This creates the main table and stored procedure
```

#### 2.2 Import Initial Data
Import your airline reviews dataset:
- Use Azure Data Factory Copy Data wizard, or
- Use SQL Server Import/Export wizard, or
- Use BULK INSERT command

```sql
-- Example BULK INSERT (adjust path as needed)
BULK INSERT preprocessed_airline_reviews4
FROM 'your-data-file.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);
```

### Phase 3: Data Factory Configuration

#### 3.1 Create Linked Services

**SQL Database Linked Service:**
1. Open Data Factory Studio
2. Manage → Linked services → New
3. Select Azure SQL Database
4. Configure connection:
   - Name: `AzureSqlDatabase1`
   - Server name: `[your-server].database.windows.net`
   - Database name: `ai_indian_airline_sentiment`
   - Authentication: System Assigned Managed Identity (recommended)

**Text Analytics Linked Service:**
1. Create new linked service
2. Select REST service
3. Configure:
   - Name: `RestLanguageService`
   - Base URL: `https://[your-service].cognitiveservices.azure.com`

#### 3.2 Create Dataset
1. Author → Datasets → New
2. Select Azure SQL Database
3. Configure:
   - Name: `AzureSqlTable1`
   - Linked service: `AzureSqlDatabase1`
   - Table: `dbo.preprocessed_airline_reviews4`

#### 3.3 Import Pipeline
1. Author → Pipelines → New pipeline
2. Copy the content from `pipeline/OpinionMiningPipeline.json`
3. Paste into the Code view of your pipeline
4. Update the API key in the CallTextAnalytics activity:
   - Replace placeholder with your actual Text Analytics key
5. Publish pipeline

#### 3.4 Create and Configure Trigger
1. Author → Triggers → New trigger
2. Import configuration from `pipeline/trigger-config.json`
3. Or manually configure:
   - Name: `AutoProcess`
   - Type: Schedule
   - Frequency: Every 2 minutes
   - Start time: Current time
4. Publish changes

### Phase 4: Testing and Validation

#### 4.1 Test Pipeline Manually
1. Go to your pipeline
2. Click Debug
3. Monitor execution in Output tab
4. Verify data is updated in database

#### 4.2 Validate Trigger
1. Monitor → Pipeline runs
2. Verify automatic execution every 2 minutes
3. Check Trigger runs for trigger health

#### 4.3 Database Validation
Run monitoring queries to verify processing:

```sql
-- Check processing progress
SELECT 
    COUNT(*) as Total,
    SUM(CASE WHEN positive_aspects IS NOT NULL THEN 1 ELSE 0 END) as Processed
FROM preprocessed_airline_reviews4;
```

### Phase 5: Monitoring Setup

#### 5.1 Azure Monitor Integration
1. Navigate to Data Factory → Monitor
2. Set up alerts for:
   - Pipeline failures
   - Long-running pipelines
   - Cost thresholds

#### 5.2 Cost Management
1. Azure Portal → Cost Management + Billing
2. Set up budget alerts
3. Monitor daily spend

## Configuration Files

### Required Environment Variables
Create a configuration file (not committed to Git):

```json
{
  "textAnalyticsEndpoint": "https://[your-service].cognitiveservices.azure.com",
  "textAnalyticsKey": "[your-key]",
  "sqlConnectionString": "Server=[server];Database=[db];Authentication=Active Directory Default;"
}
```

## Security Considerations

### API Key Management
- Never commit API keys to source control
- Use Azure Key Vault for production deployments
- Rotate keys regularly

### Database Security
- Enable firewall rules
- Use managed identity authentication
- Enable audit logging

### Network Security
- Configure virtual network integration if required
- Use private endpoints for sensitive workloads

## Troubleshooting Common Issues

### Pipeline Failures
1. Check activity details in Monitor tab
2. Verify API quotas and limits
3. Validate connection strings and credentials

### Database Connection Issues
1. Check firewall settings
2. Verify managed identity permissions
3. Test connection from Data Factory

### API Rate Limiting
1. Reduce batch size in lookup query
2. Increase trigger interval
3. Monitor API usage in Azure portal

## Performance Optimization

### Current Configuration
- Batch size: 5 reviews per execution
- Frequency: Every 2 minutes
- Expected completion: 15 hours for 2,210 reviews

### Optimization Options
1. **Increase batch size** (within API limits)
2. **Parallel processing** (requires higher pricing tier)
3. **Custom retry logic** for failed requests

## Maintenance Tasks

### Regular Monitoring
- Daily: Check pipeline execution status
- Weekly: Review cost usage
- Monthly: Analyze sentiment trends

### Data Backup
- Regular database backups
- Export processed results
- Archive raw data

### Updates and Patches
- Monitor Azure service updates
- Update API versions as needed
- Review and update security configurations

## Support Resources

### Documentation Links
- [Azure Data Factory Documentation](https://docs.microsoft.com/azure/data-factory/)
- [Text Analytics API Reference](https://docs.microsoft.com/azure/cognitive-services/text-analytics/)
- [Azure SQL Database Documentation](https://docs.microsoft.com/azure/azure-sql/)

### Community Support
- Azure Data Factory Community Forum
- Stack Overflow (tag: azure-data-factory)
- GitHub Issues for this repository