# Path to Automation

In order to make this project more automated, must do the following:

<br />

- Use config file / dynamodb state to manage the deployment of sources, targets, and unions
- https://github.com/hashicorp/terraform-exec
- 

## Database:

- [Research] Deploy RDS Proxy
- [Research] Look into replication across regions (RDS Proxy help with failover?)
- [Research] Consider Aurora
- [Research] Consider Arango - is it best for relationships between data sources?

<br />

## EKS / Consider 

- Create TF to deploy an EKS cluster
- [Research] Deploying SuperSet into EKS

<br />

## Infrastructure

- https://terragrunt.gruntwork.io/docs/getting-started/quick-start/
- https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/

<br />

## MORE LAMBDAS

End goal: 
- https://www.recordedfuture.com/threat-intelligence 
- https://intsights.com/solutions (see solutions examples)

THREAT INTELLIGENCE

SANS - https://isc.sans.edu/api/
- Threatfeeds - https://isc.sans.edu/api/#threatfeeds
    - List of Feeds
    - IPs Per Day
    - IPs Per Feed Per Day
    - Threatfeed IPs
    - Threatfeed Hostnames
    - IPs in feed category

https://abuse.ch/#platforms
- Threat Fox
- URL Haus
- Malware Bazaar
- SSL Blacklist

CISA - https://www.cisa.gov/ais

WITH FREE TRIALS AKA THE ABILITY TO TEST:

- [Snyk](https://docs.snyk.io/snyk-api-info)
    - Applications
    - Vulnerability scans per application
- [Crowdstrike](https://go.crowdstrike.com/try-falcon-prevent.html)
- [Ping](https://www.pingidentity.com/en/try-ping.html)
- Cloud SDKs?
    - AWS Loadbalancers
    - AWS EC2
    - AWS Security Groups
    - AWS WAF & WAF v2
- [GitHub](https://docs.github.com/en/rest?apiVersion=2022-11-28)
- [Bitbucket](https://developer.atlassian.com/server/bitbucket/rest/v807/intro/)
- [Okta](https://developer.okta.com/docs/reference/core-okta-api/)
    - Users
    - Groups
    - Applications
    - Devices


- [Proofpoint](https://help.proofpoint.com/Threat_Insight_Dashboard/API_Documentation)
    - Campaign
    - Forensics
    - People
    - SIEM
    - Threat
    - URL Decoder
- Crowdstrike
- Airwatch
- [Sailpoint](https://developer.sailpoint.com/idn/api/v3)
- Tenable
- Veracode
- Office365 - API call
- Delinea
- KnowBe4

npx create-docusaurus@latest circulate classic

## Generic Postgres target + dbt

- The Source API should pass the log type and the s3 key to the postgres lambda
- Each log type will have a corresponding S3 file that contains the model for that log type
- The target will then store JSON directly
- DBT will then be used to create views over the JSON
- Logs will also be stored in a downstream S3 bucket (converted to Parquet) to leverage Data Bricks

- https://speakerdeck.com/nicor88/dbt-serverless-how-to-run-dbt-in-your-aws-account?slide=19
- https://github.com/nicor88/dbt-serverless 


## Plan to create data normalization format

- Create a way to normalize data across tools (comparing and joining disparate data sources together)
- Use VRL? 
- Define our own schemas?


