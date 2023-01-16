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
	cd iac/remote-backend && \
	terraform init && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars



######################
# Initialize Modules #
######################

# Generating the provider.tf from a template allows us to utilize environment variables. Terraform does not accept Variables in the backend block.
# https://developer.hashicorp.com/terraform/language/settings/backends/configuration#using-a-backend-block

init-infra-vpc:
	cd iac/vpc && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-infra-database:
	cd iac/database && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-infra-data-lake:
	cd iac/data-lake && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-infra-services-okta:
	cd iac/services/okta/users/api && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-infra-services-create-database:
	cd iac/services/utils/database-configurator/create-database && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-infra-services-create-table:
	cd iac/services/utils/database-configurator/create-table && \
	echo "Generating provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init: init-infra-vpc \
	init-infra-data-lake \
	init-infra-database \
	init-infra-services-okta \
	init-infra-services-create-database \
	init-infra-services-create-table



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

auto-apply-infra-services-okta:
	cd iac/services/okta/users/api && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply-infra-services-create-database:
	cd iac/services/utils/database-configurator/create-database && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply-infra-services-create-table:
	cd iac/services/utils/database-configurator/create-table && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars	

auto-apply: auto-apply-infra-vpc \
	auto-apply-infra-database \
	auto-apply-infra-data-lake \
	auto-apply-infra-services-okta \
	auto-apply-infra-services-create-database \
	auto-apply-infra-services-create-table



#####################
# Destroy Resources #
#####################

auto-destroy-infra-vpc:
	cd iac/vpc && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy-infra-database:
	cd iac/database && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy-infra-services-okta:
	cd iac/services/okta/users && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy-infra-services-create-database:
	cd iac/services/utils/database-configurator/create-database && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy-infra-services-create-table:
	cd iac/services/utils/database-configurator/create-table && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

auto-destroy: auto-destroy-infra-services-create-table \
	auto-destroy-infra-services-create-database \
	auto-destroy-infra-services-okta \
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
	cd iac/services/okta/users && \
	terraform fmt
	cd - && \
	cd iac/services/utils/database-configurator/create-database && \
	terraform fmt
	cd - && \
	cd iac/services/utils/database-configurator/create-table && \
	terraform fmt
