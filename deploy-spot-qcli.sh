#!/bin/bash

# deploy-spot-qcli.sh - Script to deploy public m7i.2xlarge Ubuntu spot instance with Amazon Q CLI and Docker
# This version deploys to us-east-1 region

# Configuration - All values hardcoded, no prompts
STACK_NAME="amazon-q-spot-instance"
TEMPLATE_FILE="spot-qcli-template.yaml"
REGION="us-east-1"
SPOT_PRICE="0.15"  # Maximum spot price in USD per hour (adjusted for m7i.2xlarge)
KEY_NAME="amazon-q-key"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Template file $TEMPLATE_FILE not found."
    exit 1
fi

# Delete existing stack if it exists
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null; then
    echo "Deleting existing stack $STACK_NAME..."
    aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION
    echo "Waiting for stack deletion to complete..."
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $REGION
fi

# Deploy CloudFormation stack without any prompts
echo "Deploying CloudFormation stack $STACK_NAME in region $REGION..."
aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://$TEMPLATE_FILE \
    --parameters \
        ParameterKey=SpotPrice,ParameterValue=$SPOT_PRICE \
        ParameterKey=KeyName,ParameterValue=$KEY_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

# Wait for stack creation to complete
echo "Waiting for stack creation to complete..."
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $REGION

# Get stack outputs
echo "Stack creation completed. Getting spot fleet details..."
SPOT_FLEET_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='SpotFleetRequestId'].OutputValue" --output text)
KEY_PAIR_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='KeyPairId'].OutputValue" --output text)

# Save the private key
echo "Saving SSH private key..."
aws ec2 get-key-pair-data --key-pair-id $KEY_PAIR_ID --region $REGION --query "KeyMaterial" --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem
echo "Private key saved to ${KEY_NAME}.pem"

echo "======================================================"
echo "Public spot fleet with m7i.2xlarge deployed successfully!"
echo "Spot Fleet Request ID: $SPOT_FLEET_ID"
echo ""
echo "To check the status of your spot fleet:"
echo "aws ec2 describe-spot-fleet-instances --spot-fleet-request-id $SPOT_FLEET_ID --region $REGION"
echo ""
echo "To get instance details once it's running:"
echo "INSTANCE_ID=\$(aws ec2 describe-spot-fleet-instances --spot-fleet-request-id $SPOT_FLEET_ID --region $REGION --query \"ActiveInstances[0].InstanceId\" --output text)"
echo "aws ec2 describe-instances --instance-ids \$INSTANCE_ID --region $REGION --query \"Reservations[0].Instances[0].{InstanceId:InstanceId,PublicIpAddress:PublicIpAddress,State:State.Name,AvailabilityZone:Placement.AvailabilityZone}\" --output table"
echo ""
echo "To connect via SSH:"
echo "ssh -i ${KEY_NAME}.pem ubuntu@<instance-public-ip>"
echo "======================================================"

# Wait for instances to be created and show their status
echo "Waiting for instances to be created..."
sleep 60

# Get instance details
INSTANCE_ID=$(aws ec2 describe-spot-fleet-instances --spot-fleet-request-id $SPOT_FLEET_ID --region $REGION --query "ActiveInstances[0].InstanceId" --output text)
if [ -n "$INSTANCE_ID" ]; then
    aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[0].Instances[0].{InstanceId:InstanceId,PublicIpAddress:PublicIpAddress,State:State.Name,AvailabilityZone:Placement.AvailabilityZone}" --output table
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
        echo -e "\nTo connect to instance $INSTANCE_ID via SSH:"
        echo "ssh -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
        echo -e "\nEC2 Instance Connect URL:"
        echo "https://${REGION}.console.aws.amazon.com/ec2/home?region=${REGION}#ConnectToInstance:instanceId=${INSTANCE_ID}"
    fi
else
    echo "No instances found yet. Please check the status later with:"
    echo "aws ec2 describe-spot-fleet-request-history --spot-fleet-request-id $SPOT_FLEET_ID --region $REGION --start-time $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
fi
