ENV ?= dev



#########################
# Configure Environment #
#########################

# 1. Create remote backend
# 2. Create workspaces
# 3. Depending on make env var, select workspace to deploy into



######################
# Initialize Backend #
######################
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

# init-integrations-targets:
# 	cd integrations/targets/postgres/okta/iac/users && \
# 	echo "Generating provider.tf for ${ENV}" && \
# 	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
# 	cat provider.tf && \
# 	terraform init

init-integrations-unions:
	cd integrations/unions/okta && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-dashboard:
	cd dashboard/postgres && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf

init: init-environment \
	init-integrations-sources \
	init-integrations-unions \
	init-dashboard



########################
# Auto-apply Resources #
########################

auto-apply-infra-vpc:
	cd iac/vpc && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply-infra-database:
	cd iac/database && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply-infra-data-lake:
	cd iac/data-lake && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply-infra-services-create-database:
	cd iac/services/utils/database-configurator/create-database && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply-infra-services-create-table:
	cd iac/services/utils/database-configurator/create-table && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars	

auto-apply-infra-services-okta-api:
	cd iac/services/okta/users/api && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply: auto-apply-infra-vpc \
	auto-apply-infra-database \
	auto-apply-infra-data-lake \
	auto-apply-infra-services-create-database \
	auto-apply-infra-services-create-table \
	auto-apply-infra-services-okta-api



#####################
# Destroy Resources #
#####################

auto-destroy-infra-vpc:
	cd iac/vpc && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy-infra-database:
	cd iac/database && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy-infra-services-create-database:
	cd iac/services/utils/database-configurator/create-database && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy-infra-services-create-table:
	cd iac/services/utils/database-configurator/create-table && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy-infra-services-okta-api:
	cd iac/services/okta/users/api && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy: auto-destroy-infra-services-okta-api \
	auto-destroy-infra-database \
	auto-destroy-infra-vpc



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
