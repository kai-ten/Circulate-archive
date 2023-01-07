ENV ?= dev



####################
# Configure RESOURCES #
####################


####################
# DEPLOY RESOURCES #
####################
apply-infra-vpc:
	cd iac/vpc && \
	terraform apply --var-file=env/$(ENV).tfvars
