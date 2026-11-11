#!/bin/bash
set -e

# Step 1. Create the staging namespace with Terraform.
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# Step 2. Create the ConfigMaps for staging and production with Ansible.
ansible-playbook -i localhost, -c local ansible/playbook.yml

kubectl get configmap kk-payments-config -n kijani-staging
kubectl get configmap kk-payments-config -n default
