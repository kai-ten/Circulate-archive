ENV ?= dev



#########################
# Configure Environment #
#########################

# 1. Create remote backend
# 2. Create workspaces
# 3. Depending on make env var, select workspace to dpeploy into


####################
# APPLY RESOURCES #
####################
apply-infra-vpc:
	cd iac/vpc && \
	terraform apply --var-file=env/$(ENV).tfvars

apply-infra-database:
	cd iac/database && \
	terraform apply --var-file=env/$(ENV).tfvars

apply: apply-infra-vpc apply-infra-database

