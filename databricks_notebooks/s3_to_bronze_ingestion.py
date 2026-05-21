# Credentials
AWS_ACCESS_KEY = "AWS_ACSESS_KEY"
AWS_SECRET_KEY = "AWS_SECRET_KEY"

import urllib
encoded_secret_key = urllib.parse.quote_plus(AWS_SECRET_KEY)

# table names from s3 bucket
target_tables = ["customers", "sessions", "products", "events", "order_items", "orders", "reviews"]

# 2. Loop through each table name
for table in target_tables:
    print(f"Processing: {table}.csv")
    
    
    source_directory = f"s3a://{AWS_ACCESS_KEY}:{encoded_secret_key}@kaggle-dataset-haddy/bronze/*"
    file_filter_pattern = f"{table}.csv"
    
    target_delta_table = f"workspace.schema_bronze.{table}"
    checkpoint_directory = f"/Volumes/workspace/schema_bronze/bronzevolume/checkpoints/{table}"
    schema_directory = f"/Volumes/workspace/schema_bronze/bronzevolume/schemas/{table}"
    
    # Force-delete old checkpoints and schema
    try:
        dbutils.fs.rm(checkpoint_directory, recurse=True)
        dbutils.fs.rm(schema_directory, recurse=True)
        print(f"Cleared old checkpoint/schema state for {table}")
    except Exception:
        pass 
    
    try:
        # Read stream
        df_stream = spark.readStream \
            .format("cloudFiles") \
            .option("cloudFiles.format", "csv") \
            .option("cloudFiles.inferColumnTypes", "true") \
            .option("cloudFiles.schemaLocation", schema_directory) \
            .option("pathGlobFilter", file_filter_pattern) \
            .option("header", "true") \
            .load(source_directory) 
            
        # Write stream out
        query = df_stream.writeStream \
            .format("delta") \
            .option("checkpointLocation", checkpoint_directory) \
            .trigger(availableNow=True) \
            .outputMode("append") \
            .toTable(target_delta_table)
            
        query.awaitTermination()
        print(f"Successfully loaded data content into table: {target_delta_table}\n")
        
    except Exception as e:
        print(f"Failed processing [{table}]: {str(e)[:150]}...\n")

print("Fresh pipeline execution complete!")