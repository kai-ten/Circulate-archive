import boto3

def lambda_handler(event, context):
    # Replace bucket_name and object_key with the name of your bucket and the key of the object that you want to upload
    bucket_name = 'my-bucket'
    object_key = 'my-object'
    
    # Replace data with the data that you want to upload
    data = 'Hello, World!'
    
    # Create an S3 client
    s3 = boto3.client('s3')
    
    # Use the S3 client to upload the data to the bucket
    s3.put_object(Bucket=bucket_name, Key=object_key, Body=data)
    
    return 'Successfully uploaded data to S3'