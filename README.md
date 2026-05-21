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

---

## Current Progress & Next Steps
- [x] Phase 1: Establish AWS S3 data lake destinations.
- [x] Phase 1: Configure Databricks Auto Loader pipeline for real-time batch synchronization.
- [x] Phase 1: Lands 7 operational tables successfully into the `Bronze` Schema layer.
- [ ] Phase 2: Connect **dbt Core** locally via Databricks SQL Warehouses / Personal Compute.
- [ ] Phase 2: Build out the `Silver` layer (cleaning, deduplication, timestamp normalization).
- [ ] Phase 2: Architect the `Gold` layer dimensional star-schema models (Facts and Dimensions).
