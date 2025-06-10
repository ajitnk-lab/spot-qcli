# Amazon Q CLI Spot Instance with Docker

This repository contains a CloudFormation template and deployment script to create an EC2 spot instance with Amazon Q CLI, AWS CLI, and Docker pre-installed.

## What's Included

The CloudFormation template creates:
- An m7i.2xlarge spot instance in us-east-1 region
- VPC with public subnets across 3 availability zones
- Security group allowing SSH access
- IAM role with administrative permissions

The instance comes pre-installed with:
- AWS CLI
- Amazon Q CLI
- Docker and Docker Compose
- Python with pip and uv
- Node.js and npm with common packages

## Deployment Instructions

To deploy the spot instance:

```bash
./deploy-spot-qcli.sh
```

This script will:
1. Create a CloudFormation stack named "amazon-q-spot-instance"
2. Deploy an m7i.2xlarge spot instance with Docker and Amazon Q CLI
3. Save the SSH key for connecting to the instance
4. Display connection information once the instance is running

## Connecting to Your Instance

After deployment completes, the script will display:
- The instance ID
- The public IP address
- SSH connection command
- EC2 Instance Connect URL

Example:
```
To connect to instance i-0123456789abcdef0 via SSH:
ssh -i amazon-q-key.pem ubuntu@11.22.33.44
```

## Using Amazon Q CLI

Once connected to the instance:
- Run `q chat` to start a chat session
- Run `q --help` for more options

## Using Docker

Docker and Docker Compose are pre-installed:
- Run `docker --version` to verify Docker installation
- Run `docker compose --version` to verify Docker Compose installation
- Run `docker run hello-world` to test Docker functionality

## Instance Management

The instance includes scripts for easy management:
- `sudo /usr/local/bin/stop-instance.sh`: Stop the instance
- `sudo /usr/local/bin/start-instance.sh`: Start the instance

## Note on Spot Instances

This is a spot instance and may be interrupted if spot prices exceed your maximum bid. The default maximum price is set to $0.15 per hour.

## Files in this Repository

- `spot-qcli-template.yaml`: CloudFormation template for creating the spot instance
- `deploy-spot-qcli.sh`: Deployment script to create the CloudFormation stack
- `README.md`: This documentation file
