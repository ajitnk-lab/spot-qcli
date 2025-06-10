#!/bin/bash

# Complete SSH key setup script for Amazon Q CLI instances
set -e

REGION="us-west-2"
KEY_NAME="amazon-q-key-uswest2"
KEY_FILE="/home/ubuntu/spot-qcli/${KEY_NAME}.pem"

echo "🔑 Setting up SSH keys for Amazon Q CLI instances..."

# Step 1: Clean up existing key pair
echo "Step 1: Cleaning up existing key pair..."
aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION 2>/dev/null || echo "Key pair didn't exist"

# Step 2: Create new key pair and save private key
echo "Step 2: Creating new key pair..."
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --key-format pem \
    --key-type rsa \
    --region $REGION \
    --query 'KeyMaterial' \
    --output text > $KEY_FILE

# Step 3: Set correct permissions
echo "Step 3: Setting correct permissions..."
chmod 600 $KEY_FILE
chown ubuntu:ubuntu $KEY_FILE

# Step 4: Validate key format
echo "Step 4: Validating key format..."
if openssl rsa -in $KEY_FILE -check -noout; then
    echo "✅ Private key format is valid"
else
    echo "❌ Private key format is invalid"
    exit 1
fi

# Step 5: Display key information
echo "Step 5: Key information..."
echo "Key file: $KEY_FILE"
echo "Permissions: $(ls -la $KEY_FILE)"
echo "Key fingerprint:"
aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION --query 'KeyPairs[0].KeyFingerprint' --output text

# Step 6: Create backup copy
echo "Step 6: Creating backup copy..."
cp $KEY_FILE "${KEY_FILE}.backup"
echo "Backup created: ${KEY_FILE}.backup"

echo ""
echo "✅ SSH key setup completed successfully!"
echo ""
echo "Key file location: $KEY_FILE"
echo "Use this command to SSH: ssh -i $KEY_FILE ubuntu@<INSTANCE_IP>"
echo ""
echo "Note: You can use this same key file for all future deployments."
echo "The key is now ready for use with your EC2 instances."
