# Path to Automation

In order to make this project more automated, must do the following:

<br />


## VPC:
- ~~Deploy VPC with public and private subnets into us-east-2~~
- Create VPC endpoint for Lambda deployment region
    - Assign to private subnets that database gets deployed to

<br />


## RDS Postgres Instance(s):

- Deploy RDS with Terraform
    - If dev environment, make publicly accessible to access locally
    - In Security group, add home IP address if in dev
- Store root user credentials in AWS Secrets Manager
- AWSServiceRoleForRDS IAM role for instance
- Ensure there is an easy way to deploy Multi-AZ via TF
- [Research] Deploy RDS Proxy
- [Research] Look into replication across regions (RDS Proxy help with failover?)

<br />

## Config files:

- Store .sql files in S3

<br />

## Database Configurator

- Depends on RDS instance
- Create TF to deploy Python lambda with IAM access to RDS
- Create lambda that signs into RDS instance
    - Retrieves .sql files from S3
    - Create Schema
    - Create Table
- Create SNS topic to trigger this lambda when file named "init.txt" is loaded

<br />

## Init Database Configurator

- Depends on Database Configurator
- Save "init.txt" to S3 bucket to trigger lambda, this will kick off the .sql scripts that configure the database

<br />

## Okta Users Lambda

- Create TF to deploy Go lambda
- ~~Create Lambda to retrieve data and write to Postgres~~

<br />

## EKS

- Create TF to deploy an EKS cluster
- [Research] Deploying SuperSet into EKS
- [Research] Proper config to grant access to RDS instance

<br />

## MORE LAMBDAS

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
- Ping

