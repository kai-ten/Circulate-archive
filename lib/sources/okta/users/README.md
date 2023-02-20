# Circulate

Onboard all of your existing data into one platform.
The no-code solution to leverage the full power of your Cybersecurity posture. 


- Track your onboarding progress for a new tool
- Answer difficult questions with the click of a button
    - Are all of your servers sharing the same security toolsets? If not, which ones need to be onboarded?
    - Are all of your users being assigned to the correct groups?
    - Are any users missing group assignments that they should have?
    - Are any users assigned to groups they shouldn't be?


## Build

1. `GOARCH=amd64 GOOS=linux go build -o main main.go`
1. `zip main.zip main`
see trust-policy.md for initial create
aws lambda update-function-code --function-name okta-golang --zip-file fileb://main.zip


## Open Ended Questions
- How to handle custom APIs that require a certain data model? i.e. Domain Controller data being pushed to this platform 
    - Create a UI for onboarding custom data
        - Must be able to create the struct for the Golang function
        - Must be able to create the table for CockroachDB
        - Must be able to receive data pushed to it, rather than pulling from APIs

- First time load is different logic
    - Retrieves data, parses fields
    - Builds out DDL for custom fields
    - Builds out Struct for golang
    - Updates modify these files that get stored for the account in S3

- Subsequent queries find whether new fields exist or not

## Resources

- [Okta Golang SDK GitHub](https://github.com/okta/okta-sdk-golang)
- [AWS Lambda Golang](https://docs.aws.amazon.com/lambda/latest/dg/lambda-golang.html)

Not every endpoint has a method, must create struct for these:
- https://github.com/okta/okta-sdk-golang#call-other-api-endpoints

OKTA TYPES
- https://github.com/okta/okta-sdk-golang/tree/e9ca83359ec20bbd5785067ac6a1d45c765a52b4/okta

OKTA USER SCHEMA
- https://developer.okta.com/docs/reference/api/schemas/#user-profile-subschemas

AWS SuperSet Example:
- https://aws.amazon.com/solutions/implementations/apache-superset/
