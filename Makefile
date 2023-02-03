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
	echo "Generating vpc provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init && \
	cd ../data-lake && \
	echo "Generating data-lake provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init && \
	cd ../integration-state && \
	echo "Generating integration-state provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-integrations-sources:
	cd integrations/sources/okta/users/iac && \
	echo "Generating okta users provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init && \
	cd ../../applications/iac && \
	echo "Generating okta applications provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-integrations-targets:
	cd integrations/targets/postgres/iac && \
	echo "Generating postgres target provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init && \
	cd ../../s3/iac && \
	echo "Generating s3 target provider.tf for ${ENV}" && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-integrations-unions:
	cd integrations/unions/okta && \
	echo "Generating okta unions provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-integrations-transforms:
	cd integrations/transforms/okta/users/iac && \
	echo "Generating okta unions provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init-dashboard:
	cd dashboard/postgres/iac/db && \
	echo "Generating dashboard postgres db provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init && \
	cd ../create-schema && \
	echo "Generating database schema provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init && \
	cd ../create-lnd-table && \
	echo "Generating landing table provider.tf for ${ENV}..." && \
	sed s/ENV/${ENV}/ < provider.tf.template > provider.tf && \
	cat provider.tf && \
	terraform init

init: init-environment \
	init-integrations-sources \
	init-integrations-targets \
	init-integrations-unions \
	init-integrations-transforms \
	init-dashboard



########################
# Auto-apply Resources #
########################

auto-apply-environment:
	cd environment/vpc && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../data-lake && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../integration-state && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

auto-apply-integrations:
	cd integrations/sources/okta/users/iac && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/sources/okta/applications/iac && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/targets/postgres/iac && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/targets/s3/iac && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/transforms/okta/users/iac && \
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
	auto-apply-integrations \
	auto-apply-dashboard

transform:
	cd integrations/transforms/okta/users/iac && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

unions:
	cd integrations/unions/okta && \
	terraform apply -auto-approve --var-file=env/$(ENV).tfvars

#####################
# Destroy Resources #
#####################

# Destroy issues:
# - Must remove repo images before destroying ECR repo
# - Force delete secret name
# - aws secretsmanager delete-secret --secret-id /circulate-dev/postgres/credentials --force-delete-without-recovery --region us-east-2
# - aws secretsmanager delete-secret --secret-id /circulate-dev/okta/credentials --force-delete-without-recovery --region us-east-2

destroy-environment:
	cd environment/vpc && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../integration-state && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

destroy-integrations:
	cd integrations/unions/okta && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/sources/okta/users/iac && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/sources/okta/applications/iac && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/targets/postgres/iac && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/targets/s3/iac && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd - && \
	cd integrations/transforms/okta/users/iac && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

destroy-dashboard:
	cd dashboard/postgres/iac/db && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../create-schema && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars && \
	cd ../create-lnd-table && \
	terraform destroy -auto-approve --var-file=env/$(ENV).tfvars

destroy: destroy-dashboard \
	destroy-integrations \
	destroy-environment



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
