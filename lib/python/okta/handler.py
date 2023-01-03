import json
import requests

def lambda_handler(event, context):
    # Replace with your Okta Workforce endpoint URL
    endpoint_url = "https://dev-52108562-admin.okta.com/api/v1/users"
    
    # Set the headers for the request
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "SSWS 00qSTBCo2QJiEvM_SHqZS3P0fBSgqySScCja3BKkv7"
    }
    
    # Send the GET request to the endpoint, using chunked encoding
    response = requests.get(endpoint_url, headers=headers, stream=True)
    
    # Initialize a list to store the response chunks
    response_chunks = []
    
    # Read the response in chunks of up to 3 MiBs
    for chunk in response.iter_content(chunk_size=3145728):
        # Append each chunk to the list
        response_chunks.append(chunk)
    
    # Concatenate the chunks into a single bytes object
    response_bytes = b''.join(response_chunks)
    
    # Decode the bytes object as a JSON string
    response_json_str = response_bytes.decode('utf-8')
    
    # Parse the JSON string as a Python object
    response_json = json.loads(response_json_str)

    print(response_json)
    
    # Return the parsed JSON object
    return response_json
