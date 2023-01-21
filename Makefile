ENV ?= dev



#########################
# Configure Environment #
#########################

# 1. Create remote backend
# 2. Create workspaces
# 3. Depending on make env var, select workspace to deploy into



#################################
# Initialize and Deploy Backend #
#################################
backend:
	cd environment/remote-backend && \
	terraform init && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \


######################
# Initialize Modules #
######################

# Generating the provider.tf from a template allows us to utilize environment variables. Terraform does not accept Variables in the backend block.
# https://developer.hashicorp.com/terraform/language/settings/backends/configuration#using-a-backend-block

init-environment:
	cd environment/remote-backend && \
	terraform init && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../vpc && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init && \
	cd ../data-lake && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-integrations-sources:
	cd integrations/sources/okta/iac/users && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-integrations-targets:
	cd integrations/targets/postgres/iac && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-integrations-unions:
	cd integrations/unions/okta && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-dashboard:
	cd dashboard/postgres/iac/db && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init && \
	cd ../create-schema && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init && \
	cd ../create-lnd-table && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init: init-environment \
	init-integrations-sources \
	init-integrations-unions \
	init-dashboard



########################
# Auto-apply Resources #
########################

auto-apply-environment:
	cd environment/vpc && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../data-lake && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply-integrations:
	cd integrations/sources/okta/iac/users && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/targets/postgres/iac && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/unions/okta && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply-dashboard:
	cd dashboard/postgres/iac/db && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../create-schema && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../create-lnd-table && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply: auto-apply-environment \
	auto-apply-integrations


#####################
# Destroy Resources #
#####################

destroy-environment:
	cd environment/vpc && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../data-lake && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

destroy-integrations:
	cd integrations/sources/okta/iac/users && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/unions/okta && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

apply-dashboard:
	cd dashboard/postgres/iac && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy: auto-destroy-dashboard \
	auto-destroy-integrations \
	auto-destroy-environment



####################
# Format Resources #
####################

fmt:
	cd iac/remote-backend && \
	terraform fmt && \
	cd - && \
	cd iac/vpc && \
	terraform fmt && \
	cd - && \
	cd iac/database && \
	terraform fmt && \
	cd - && \
	cd iac/data-lake && \
	terraform fmt && \
	cd - && \
	cd iac/services/okta/users/api && \
	terraform fmt
	cd - && \
	cd iac/services/utils/database-configurator/create-database && \
	terraform fmt
	cd - && \
	cd iac/services/utils/database-configurator/create-table && \
	terraform fmt
