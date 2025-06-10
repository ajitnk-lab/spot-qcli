#!/bin/bash

# deploy-spot-qcli-uswest2.sh - Script to deploy public spot instance with Amazon Q CLI and Docker in us-west-2
# This version uses mixed instance types across multiple AZs for better availability

# Configuration - All values hardcoded, no prompts
STACK_NAME="amazon-q-spot-instance-uswest2"
TEMPLATE_FILE="spot-qcli-template-uswest2.yaml"
REGION="us-west-2"
SPOT_PRICE="0.25"  # Maximum spot price in USD per hour (increased to handle current market prices)
KEY_NAME="amazon-q-key-uswest2"

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
echo "Using mixed instance types: m5.2xlarge, m5a.2xlarge, m4.2xlarge, c5.2xlarge"
echo "Across 4 availability zones for better spot availability"

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

if [ -n "$SPOT_FLEET_ID" ]; then
    echo "Spot Fleet Request ID: $SPOT_FLEET_ID"
    
    # Get active instances
    echo "Getting active spot instances..."
    aws ec2 describe-spot-fleet-instances --spot-fleet-request-id $SPOT_FLEET_ID --region $REGION
    
    # Get instance details
    echo "Getting instance details..."
    INSTANCE_IDS=$(aws ec2 describe-spot-fleet-instances --spot-fleet-request-id $SPOT_FLEET_ID --region $REGION --query "ActiveInstances[].InstanceId" --output text)
    
    if [ -n "$INSTANCE_IDS" ]; then
        echo "Active Instance IDs: $INSTANCE_IDS"
        
        # Get public IP addresses
        for INSTANCE_ID in $INSTANCE_IDS; do
            PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
            INSTANCE_TYPE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[0].Instances[0].InstanceType" --output text)
            AZ=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[0].Instances[0].Placement.AvailabilityZone" --output text)
            
            echo "Instance $INSTANCE_ID ($INSTANCE_TYPE in $AZ): Public IP = $PUBLIC_IP"
            
            if [ "$PUBLIC_IP" != "None" ] && [ "$PUBLIC_IP" != "null" ]; then
                echo "SSH Command: ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP"
                echo "SSM Command: aws ssm start-session --target $INSTANCE_ID --region $REGION"
            fi
        done
    else
        echo "No active instances found yet. The spot fleet may still be launching instances."
    fi
else
    echo "Failed to get Spot Fleet Request ID"
fi

echo ""
echo "=== Deployment Summary ==="
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "Instance Types: m5.2xlarge, m5a.2xlarge, m4.2xlarge, c5.2xlarge"
echo "Max Spot Price: \$$SPOT_PRICE/hour"
echo "Key Pair: $KEY_NAME"
echo ""
echo "The mixed instance type configuration provides:"
echo "- Better spot availability across multiple instance families"
echo "- Deployment across 4 availability zones in us-west-2"
echo "- Lower interruption rates compared to us-east-1"
echo ""
echo "To check instance status later:"
echo "aws ec2 describe-spot-fleet-instances --spot-fleet-request-id $SPOT_FLEET_ID --region $REGION"
