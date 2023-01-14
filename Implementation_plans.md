# Path to Automation

In order to make this project more automated, must do the following:

<br />

## RDS Postgres Instance(s):

- [Research] Deploy RDS Proxy
- [Research] Look into replication across regions (RDS Proxy help with failover?)

<br />

## Init Database Configurator

- Depends on Database Configurator
- Save "init.txt" to S3 bucket to trigger lambda, this will kick off the .sql scripts that configure the database

<br />

## Okta Users Lambda

- ~~Create TF to deploy Go lambda~~
- ~~Create Lambda to retrieve data and write to Postgres~~
- Convert Lambda into Step Function for future goals (e.g. multi-database support)

<br />

## EKS / Consider 

- Create TF to deploy an EKS cluster
- [Research] Deploying SuperSet into EKS
- [Research] Proper config to grant access to RDS instance

<br />

## Documentation Practices

- Use Rover to visualize each projects architecture

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

