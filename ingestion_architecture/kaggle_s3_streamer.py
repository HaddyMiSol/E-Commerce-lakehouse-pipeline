import os
import boto3
import urllib3
import json

def lambda_handler(event, context):
    # read environmental variables
    kaggle_user = os.environ['KAGGLE_USERNAME']
    kaggle_key = os.environ['KAGGLE_KEY']
    s3_bucket = os.environ['S3_BUCKET_NAME']
    
    # Kaggle dataset owner and slug
    owner = "wafaaelhusseini"
    dataset = "e-commerce-transactions-clickstream"
    
    # list of all csv files
    filenames = [
        "customers.csv",
        "products.csv",
        "sessions.csv",
        "events.csv",
        "orders.csv",
        "order_items.csv",
        "reviews.csv"
    ]
    
    # Initialize HTTP client and S3 client
    headers = urllib3.util.make_headers(basic_auth=f"{kaggle_user}:{kaggle_key}")
    http = urllib3.PoolManager()
    s3_client = boto3.client('s3')
    
    successfully_ingested = []
    failed_ingested = []
    
    # loop through each file and stream it to S3
    for filename in filenames:
        url = f"https://www.kaggle.com/api/v1/datasets/download/{owner}/{dataset}/{filename}"
        s3_key = f"bronze/{filename}"
        
        print(f"Starting stream for: {filename}...")
        
        try:
            # requesting data stream for the current file
            response = http.request('GET', url, headers=headers, preload_content=False)
            
            if response.status == 200:
                # stream directly to S3
                s3_client.upload_fileobj(response, s3_bucket, s3_key)
                print(f"Successfully streamed {filename} to s3://{s3_bucket}/{s3_key}")
                successfully_ingested.append(filename)
            else:
                print(f"Failed to download {filename}. HTTP Status: {response.status}")
                failed_ingested.append(filename)
                
        except Exception as e:
            print(f"Error processing {filename}: {str(e)}")
            failed_ingested.append(filename)
            continue  
            
    # pipeline summary
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Multi-file ingestion execution complete',
            'successful_files': successfully_ingested,
            'failed_files': failed_ingested
        })
    }
