aws iam create-role --role-name lambda-ex --assume-role-policy-document file://trust-policy.json

{
    "Role": {
        "Path": "/",
        "RoleName": "lambda-ex",
        "RoleId": "AROAUK3SWHK5TUL3OBVCM",
        "Arn": "arn:aws:iam::298203888315:role/lambda-ex",
        "CreateDate": "2023-01-01T07:52:29+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "lambda.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}

aws iam attach-role-policy --role-name lambda-ex --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws lambda create-function --function-name okta-golang --runtime go1.x --role arn:aws:iam::298203888315:role/lambda-ex --handler main --zip-file fileb://main.zip
