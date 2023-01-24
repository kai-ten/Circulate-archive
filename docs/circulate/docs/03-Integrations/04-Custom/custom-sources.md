---
id: Custom Sources
---

Sources require two things to be configured:

- The infrastructure to deploy a lambda
- Source code to retrieve data from the API
    - SIDE NOTE: Right now, this also writes to S3 by default. This is because the Step Function uses S3 to transfer data between steps - otherwise the data is limited to [256KB per response body size](https://aws.amazon.com/about-aws/whats-new/2020/09/aws-step-functions-increases-payload-size-to-256kb/). In the future, we should create an S3 target separate from this functionality. Then, we take this integration bucket and define a retention policy of 
    X day(s) so that the bucket doesn't grow unnecessarily large.


Sources are logically grouped by the Log Source and by the API data being retrieved. <br />
Look at the [Okta Source](https://github.com/kai-ten/Circulate/tree/master/integrations/sources/okta) code for example -

At the highest level, the integration is separated by 'iac' and by 'lib'.

---

## IaC

Someday I hope to improve this process by having logic that iterates over libraries and generates lambdas for each lib that is found. Or something easier like that. 
Rather than having to build the infra for each and every endpoint.

One step at a time though.

### An Example with Okta Users API

Looking at the [Okta IaC code](https://github.com/kai-ten/Circulate/tree/master/integrations/sources/okta/iac/users), it's first important to note that the terraform code 
is contained within a `users` directory. This is intended to separate any API endpoints, so that each lambda is dedicated to it's own endpoint. Within /users/main.tf, multiple [User API](https://developer.okta.com/docs/reference/api/users/) endpoints may be included here such as getting all users, getting a user, creating a user, etc.

The goal will be to leverage all CRUD operations on an endpoint, so that we can create a [SOAR platform](https://www.gartner.com/en/information-technology/glossary/security-orchestration-automation-response-soar) in the long-term.

EVERY endpoint will have a lib of its own, which means that every endpoint will be its own lambda. See line 26 on main.tf in `iac/users/main.tf`. <br />
This lambda (needs a module name change to "okta_list_users_api") is dedicated to listing all users that exist in Okta, and refers to the source code on line 


### An Example for an API that does not exist yet

Another API endpoint that Okta would benefit from would be the [Applications API](https://developer.okta.com/docs/reference/api/apps/). In this API would be the ability to retrieve the Applications in an org, as well as the Users and Groups that are related to the Application. 

The Applications API endpoint would be realized in an IaC dir of it's own such as `applications`. 

---

## Lib

### Requirements for a successful Source integration:

- API retries
- Pagination / Loading in bulk (e.g. 3MB per HTTP request, 1000 objects per request, etc.)
- JSON Array format
- Eventually support incremental loads or full data refreshes
    - Starting with incremental support
- Use DynamoDB Integration State to be driven by last successful run time / any other audit data

### My development process:

__THIS CAN BE IMPROVED BY CREATING A PROCESS TO RUN LAMBDAS LOCALLY [like this](https://levelup.gitconnected.com/run-go-aws-lambda-locally-with-localstack-and-serverless-framework-5c80894f389c)__

In the meantime, this is the quuickest path to deploy:

1. Copy and paste the entire `okta/lib/users` file base and paste it into `applications`
2. Delete all code in `main.go` except for `main` and `handleRequest`
3. Add Log.Print("Hello")
4. Ensure the IaC has a module in main.tf that is capable of deploying this `applications` lambda
5. Run the lambda, confirm that you see your printed message in Cloudwatch logs

In `okta/iac/applications`..

- `terraform init --var-file dev.tfvars` (only necessary once / if you change the module)
- `terraform apply --auto-approve`, for quickest way to deploy & test


### Okta-specific APIs

We are lucky for Okta to provide us with a Golang SDK. See the Users implementation to get an idea for how that works.


### APIs that have no SDK

- Try to find any OpenAPI spec, Golang has a couple of libs that are good for converting OpenAPI spec to Go SDK code
- Will have to use standard Go libs, batch messages by object count / payload size, etc.


Is Go ultimately the right answer? <br />
Python is a big player in data, and may also be a good language to leverage

