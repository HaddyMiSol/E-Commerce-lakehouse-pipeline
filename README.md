# E-Commerce Lakehouse Platform (Medallion Architecture)

## Project Overview
This project demonstrates the design and deployment of an end-to-end Data Lakehouse platform leveraging a **Medallion Architecture** (`Bronze` -> `Silver` -> `Gold`) built entirely on **Databricks Serverless Compute**, **AWS S3**, and **dbt Core**. 

The pipeline ingests multi-part e-commerce retail data streams from a Kaggle API endpoint, automates dynamic schema-isolated ingestion, transforms raw operational logs into clean dimensional models, and serves analytics-ready tables for business intelligence tracking.

---

## System Architecture (Phase 1)
The data platform is engineered with a completely decoupled storage and compute layer, utilizing zero-local-footprint serverless microservices:

[Kaggle API] 
     │
     ▼ (Zero-Local-Footprint Streaming via Python/Boto3)         
[AWS S3 Bucket: `kaggle-dataset-haddy/bronze/`]
     │
     ▼ (Incremental Batch Loading via Auto Loader)
[Databricks Serverless Compute] ──(Unity Catalog Managed Volumes)──► [Metadata Checkpoints/Schemas] 
     │
     ▼ (Dynamic Multi-Table Loop)
[Workspace Catalog: `schema_bronze` Schema Delta Tables] 

See images below;

![System Architecture](./images/kaggle_s3_streamer.png)
![System Architecture](./images/s3_databricks_ingestion.png)
![System Architecture](./images/tables.png)

---

## Tech Stack
* **Cloud Infrastructure:** Amazon Web Services (S3, IAM)
* **Data Platform & Engine:** Databricks Serverless (Runtime 15.x+, Apache Spark)
* **Data Governance & Security:** Unity Catalog Managed Volumes
* **Inference Storage Format:** Delta Lake (Parquet-backed ACID transactions)
* **Languages:** Python (PySpark, Boto3, Urllib)

---

## Key Engineering Achievements & Blockade Resolutions

### 1. Fully Automated Multi-Table Ingestion Loop
* **The Challenge:** The source S3 storage bucket holds 7 distinct e-commerce entity files (`customers`, `sessions`, `products`, `events`, `order_items`, `order`, `reviews`) loose in a flat directory. Standard Auto Loader scripts gets strict, rigid sub-directories.
* **The Solution:** Engineered a dynamic Python orchestration loop using PySpark Structured Streaming. The script iteratively mounts the root S3 path, generates decoupled target metadata configurations, and uses a `pathGlobFilter` pattern to simultaneously extract, schema-infer, and isolate all 7 datasets into native, high-performance Delta tables inside the `Bronze` schema.

### 2. Overcoming Serverless Cloud Isolation & Security Restraints
* **The Challenge:** Migrating to modern **Databricks Serverless Compute** limits notebook permissions. Legacy Hadoop Spark session-level property declarations (`spark._jsc.hadoopConfiguration`) and old Root DBFS access paths (`dbfs:/`) are completely locked down and blocked (`SQLSTATE: 42K0I` / `56038`), preventing S3 credential mapping.
* **The Solution:** Bypassed the compute restrictions by implementing url-encoded IAM runtime string injections combined with session-level path routing. Wiped old corrupted pipeline states and routed streaming metadata checkpoints and schema evolution snapshots safely into managed **Unity Catalog Volumes** (`/Volumes/workspace/schema_bronze/bronzevolume/`).
  
### 3. Modularizing the Silver Transformation Layer via dbt Core (Phase 2)
* **The Challenge:** Moving from raw, untyped `Bronze` strings to structured data requires a scalable environment that isolates code from materialization logic, while running directly on high-performance compute.
* **The Solution:** Locally configured and integrated **dbt Core** connected via a Databricks Serverless SQL Warehouse. Refactored the raw structures by isolating reading routes strictly from `schema_bronze` and directing compiled physical table routing to a completely isolated `schema_silver` data layer. Implemented strict casting (standardizing timestamps and forcing monetary metrics to exact `decimal(10,2)` structures to prevent float-rounding bugs).

### 4. Proactive Data Governance & Handling Logical Anomalies (Phase 2)
* **The Challenge:** Real-world raw transactional data contains structural degradation that breaks downstream metrics if left unchecked.
* **The Solution:** Implemented an automated testing framework utilizing `dbt-utils`. The data quality suite captured critical business rule violations:
  * Detected **19,000+ anomalous records** where order item subtotals mathematically exceeded checkout totals.
  * Caught temporal anomalies where a customer's `signup_date` falsely trailed their `first_order_date` (due to timezone variance or guest checkouts).
  * **Resolution:** Engineered defensive transformation logic within `generated_customer_first_order.sql` and the staging layers using conditional SQL expressions (`case when` boundary capping and strict filtering) to self-heal anomalies automatically at runtime.
 
See images below;

![dbt Debug Log](./images/dbt%20debug.png)
![dbt Run Log](./images/dbt%20run%201.png)
![Initial Test Failure](./images/failed%20test%201.png)
![First Test Resolution](./images/failed%20test%201%20resolve.png)
![Second Test Failure](./images/failed%20test%202.png)
![Second Test Resolution Part 1](./images/failed%20test%202%20resolved%201.png)
![Second Test Resolution Part 2](./images/failed%20test%202%20resolved.png)
![Staging Data Profile](./images/staging%20data.png)

---

## Directory Layout
```text
ecommerce_lakehouse_pipeline/
├── databricks_notebooks/      # Phase 1: Python/PySpark Ingestion Scripts
├── ingestion_architecture/    # System configuration mappings
└── ecommerce_lakehouse_dbt/   # Phase 2: Complete dbt Core Workspace
    ├── models/
    │   ├── staging/           # Silver Layer: Staging models & custom schema validations
    │   └── marts/             # Gold Layer: Dimensional star-schema models
    ├── dbt_project.yml        # Core framework configurations
    └── packages.yml           # External open-source testing dependencies (dbt utils)
```


## Current Progress & Next Steps
- [x] Phase 1: Establish AWS S3 data lake destinations.
- [x] Phase 1: Configure Databricks Auto Loader pipeline for real-time batch synchronization.
- [x] Phase 1: Lands 7 operational tables successfully into the `Bronze` Schema layer.
- [x] Phase 2: Connect **dbt Core** locally via Databricks SQL Warehouses / Personal Compute.
- [x] Phase 2: Build out the `Silver` layer (cleaning, deduplication, timestamp normalization).
- [x] Phase 2: Implement automated testing/data quality check and handle real-world logical data anomalies.
- [ ] Phase 3: Architect the `Gold` layer dimensional star-schema models (Facts and Dimensions).
