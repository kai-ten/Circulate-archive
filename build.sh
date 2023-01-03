#! /bin/sh

# Build okta app
cd ./lib/python/okta
pip install -r requirements.txt -t ./python --upgrade
zip -r ../../assets/okta-libs.zip ./python
cd -

# Apply terraform
cd ./iac
terraform apply -auto-approve
cd -