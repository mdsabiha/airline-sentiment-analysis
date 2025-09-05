# ✈️ Airline Sentiment Analysis – Azure Data Factory

![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?logo=microsoft-azure&logoColor=white)
![ADF](https://img.shields.io/badge/Azure%20Data%20Factory-0078D4)
![SQL](https://img.shields.io/badge/Azure%20SQL-003B57)
![Cognitive Services](https://img.shields.io/badge/Azure%20Cognitive%20Services-0078D4)

## 🎯 Goal
Perform **aspect-based opinion mining** on Indian airline reviews using **Azure Cognitive Services (Text Analytics)**, orchestrated with **Azure Data Factory (ADF)**, and persisted to **Azure SQL Database**.

## 🏗️ Architecture
- **Azure Data Factory** – Pipeline orchestration
- **Azure Cognitive Services (Language/Text Analytics)** – Opinion mining
- **Azure SQL Database** – Storage (table: `dbo.preprocessed_airline_reviews4`)
- **Managed Identity / API Key** – Auth between services

## 🚦 Pipeline Flow
1. **Lookup**: Fetch a batch of unprocessed reviews  
2. **ForEach** (sequential): Iterate per review  
3. **Web Activity**: Call Text Analytics (opinionMining=true)  
4. **Stored Procedure**: Upsert aspects + mixed flag to SQL

## 📊 Data Model (key columns)
- `ReviewID` **UNIQUEIDENTIFIER (PK)**
- `review_text` **NVARCHAR(MAX)**
- `positive_aspects` **NVARCHAR(300)**
- `negative_aspects` **NVARCHAR(300)**
- `is_mixed_review` **BIT**

> Full schema & scripts → [`sql/`](./sql)

## ✅ Results
- 2,210+ reviews processed in controlled batches (e.g., TOP 5)
- Extracted **positive/negative aspects** per review
- **Mixed sentiment** flagged
- Robust handling for nulls and field length limits

## 📂 Repo Layout
- `docs/` – Detailed docs (overview, pipeline, schema, deployment, roadmap)  
- `sql/` – Table + stored procedure scripts  
- `adf_export/` – ADF pipeline HTML export (upload yours here)  

## 🚀 Getting Started
1. Create the table & stored procedure:  
   ```bash
   # run in Azure SQL (e.g., Azure Data Studio)
   sql/schema.sql
   sql/stored_procedure.sql
