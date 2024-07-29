# ToDo List Application Deployment Guide

## Overview

This guide provides step-by-step instructions to deploy a Flask-based ToDo List application on an Amazon Linux EC2 instance using Terraform for infrastructure provisioning and Ansible for configuration management. The application is integrated with AWS S3 for static file hosting and MySQL for database services.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Terraform installed
- Ansible installed
- jq installed for JSON parsing
- A GitHub repository containing the Flask application

## Directory Structure

```
todo_assessment2/
├── ansible/
│   ├── ansible.cfg
│   ├── playbook.yml
│   ├── hosts (created dynamically)
│   ├── terraform_outputs.json (created dynamically)
├── terraform/
│   ├── iam.tf
│   ├── main.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   ├── variables.tf
└── run-me.sh
```

## Setup Steps

### Pre-Deployment Configuration setup

You will need to update the following files with your specific AWS resource details and credentials:

- `terraform.tfvars`: Update the variable values such as VPC ID, Subnet ID, Key pair name, S3 bucket name, AMI ID, and EC2 instance type.

- `ansible/playbook.yml`: Update the MySQL credentials by changing the value of `MYSQL_DATABASE` to your desired database name.

- `run-me.sh`: Update the path to your `key.pem` file by modifying the value of `KEY_PATH` to the correct file path.

These updates are necessary before running the deployment bash script `run-me.sh`.

````sh

### Step 1: Executing the Deployment Script

1. **Navigate to the project root directory**:

   ```sh
   cd todo_assessment2
````

2. **Run the deployment script**:
   ```sh
   ./run-me.sh
   ```

The script `run-me.sh` will automate the following tasks:

- Navigate to the Terraform directory and apply the configuration to provision the necessary AWS resources.
- Capture the Terraform outputs in JSON format.
- Extract the EC2 public IP from the Terraform outputs and create an Ansible hosts file with the updated IP address.
- Wait for the EC2 instance to be fully online.
- Navigate to the Ansible directory and run the playbook to configure and deploy the Flask application.

### Step 2: Manual Verification (if needed)

If you encounter any issues, you can manually verify and execute the steps as follows:

1. **Navigate to the Terraform directory**:

   ```sh
   cd terraform/
   ```

2. **Initialize Terraform**:

   ```sh
   terraform init
   ```

3. **Apply the Terraform configuration**:

   ```sh
   terraform apply --auto-approve
   ```

4. **Capture Terraform outputs**:

   ```sh
   terraform output -json > ../ansible/terraform_outputs.json
   ```

5. **Navigate to the Ansible directory**:

   ```sh
   cd ../ansible/
   ```

6. **Create and configure the hosts file**:

   ```sh
   EC2_PUBLIC_IP=$(jq -r '.ec2_instance_public_ip.value' < terraform_outputs.json)
   cat <<EOL > hosts
   [web]
   ec2-${EC2_PUBLIC_IP//./-}.compute-1.amazonaws.com ansible_user=ec2-user ansible_ssh_private_key_file=/path/to/your/key.pem
   EOL
   ```

7. **Run the Ansible playbook**:
   ```sh
   ansible-playbook -i hosts playbook.yml --private-key /path/to/your/key.pem
   ```

## File Descriptions

### `terraform/iam.tf`

This file defines IAM resources for granting EC2 instances access to an S3 bucket:

- IAM role (`aws_iam_role.ec2_s3_role`) allowing EC2 instances to assume the role.
- IAM policy (`aws_iam_policy.s3_access`) granting specific S3 bucket actions.
- IAM role policy attachment (`aws_iam_role_policy_attachment.s3_access_attachment`) attaching the policy to the role.
- IAM instance profile (`aws_iam_instance_profile.ec2_s3_profile`) associating the role with EC2 instances.

### `terraform/main.tf`

This file defines the main infrastructure resources, including:

- Querying the latest Amazon Linux 2 AMI ID.
- Security group for the backend server.
- EC2 instance configuration for the backend server.
- S3 bucket and its configurations for hosting static files.

### `terraform/provider.tf`

This file specifies the required Terraform providers and their versions. It also sets up the AWS provider with the region specified in the variables.

### `terraform/terraform.tfvars`

This file contains the variable values used in the Terraform configuration, such as:

- VPC ID
- Subnet ID
- Key pair name
- AWS region
- S3 bucket name
- AMI ID
- EC2 instance type

### `terraform/variables.tf`

This file defines the variables used in the Terraform configuration, including:

- AWS region
- VPC ID
- Subnet ID
- Key pair name
- S3 bucket name
- AMI ID
- EC2 instance type

### `ansible/ansible.cfg`

This file contains Ansible configuration settings, such as:

- Inventory file location
- Host key checking settings

### `ansible/playbook.yml`

This playbook sets up the Flask application on an Amazon Linux EC2 instance. It includes tasks for:

- Updating all packages
- Installing Git, Python 3, pip, and Nginx
- Cloning the Flask application repository
- Creating a virtual environment
- Installing Python dependencies
- Creating a `.env` file with MySQL credentials
- Creating the MySQL database if it doesn't exist
- Configuring and running the Flask application with Gunicorn
- Setting up Nginx as a reverse proxy for Gunicorn

### `run-me.sh`

This script automates the deployment process by:

- Navigating to the Terraform directory and applying the configuration.
- Capturing Terraform outputs in JSON format.
- Extracting the EC2 public IP and creating an Ansible hosts file with the updated IP address.
- Waiting for the EC2 instance to be fully online.
- Navigating to the Ansible directory and running the playbook.

## How to Use This Repository

1. **Clone the repository** to your local machine.
2. **Navigate to the project root directory**:
   ```sh
   cd todo_assessment2
   ```
3. **Execute the run script**:
   ```sh
   ./run-me.sh
   ```
4. **Monitor the script output** to ensure all steps are executed successfully. If there are any errors, review the detailed steps and logs to troubleshoot.

By following these steps, you will have a fully deployed Flask-based ToDo List application running on an Amazon Linux EC2 instance, with static files hosted on S3 and the database managed by MySQL.
