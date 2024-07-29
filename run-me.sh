#!/bin/bash

# Set directories
TERRAFORM_DIR="terraform"
ANSIBLE_DIR="ansible"
KEY_PATH="/Users/chadthompsonsmith/DevOpsBravo/week-1/keys/cpclass-devopsew-bravo.pem"

# Navigate to the Terraform directory and apply configuration
cd $TERRAFORM_DIR
terraform apply --auto-approve

# Capture Terraform outputs in JSON format
terraform output -json > ../${ANSIBLE_DIR}/terraform_outputs.json

# Extract the new EC2 public IP from the Terraform outputs
EC2_PUBLIC_IP=$(jq -r '.ec2_instance_public_ip.value' < ../${ANSIBLE_DIR}/terraform_outputs.json)

# Create the new Ansible hosts file with the updated IP address
cat <<EOL > ../${ANSIBLE_DIR}/hosts
[web]
ec2-${EC2_PUBLIC_IP//./-}.compute-1.amazonaws.com ansible_user=ec2-user ansible_ssh_private_key_file=${KEY_PATH}
EOL

# Wait for the EC2 instance to be fully online
echo "Waiting for EC2 instance to be fully online..."
sleep 15

# Navigate to the Ansible directory and run the playbook
cd ../$ANSIBLE_DIR
ansible-playbook -i hosts playbook.yml --private-key ${KEY_PATH}