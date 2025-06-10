# Amazon Q CLI Spot Instance Deployment

This repository contains the infrastructure and deployment scripts for running Amazon Q CLI on AWS EC2 Spot Instances with mixed instance types for better availability and cost optimization.

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Bash shell environment
- Internet connectivity

### Deploy the Stack
```bash
cd /home/ubuntu/spot-qcli
./deploy-spot-qcli-uswest2.sh
```

### SSH to Instance
```bash
ssh -i amazon-q-key-uswest2.pem ubuntu@<INSTANCE_IP>
```

**Example with connection options:**
```bash
ssh -i amazon-q-key-uswest2.pem -o ConnectTimeout=15 -o StrictHostKeyChecking=no ubuntu@52.38.180.41
```

## 📁 Essential Files

| File | Description |
|------|-------------|
| `spot-qcli-template-uswest2.yaml` | CloudFormation template with mixed instance types |
| `deploy-spot-qcli-uswest2.sh` | Automated deployment script |
| `amazon-q-key-uswest2.pem` | SSH private key for instance access |
| `setup-ssh-keys.sh` | SSH key management and validation script |

## 🏗️ Infrastructure Overview

### Configuration
- **Region:** us-west-2 (Oregon)
- **Instance Types:** Mixed for better spot availability
  - m5.2xlarge (General purpose)
  - m5a.2xlarge (AMD-based alternative)
  - m4.2xlarge (Older generation, more stable)
  - c5.2xlarge (Compute optimized)
- **Availability Zones:** 4 AZs (us-west-2a, us-west-2b, us-west-2c, us-west-2d)
- **Max Spot Price:** $0.25/hour
- **Allocation Strategy:** Diversified across instance types and AZs

### Features
- ✅ Amazon Q CLI pre-installed and configured
- ✅ Docker and Docker Compose
- ✅ AWS CLI
- ✅ Python 3, pip, and uv package manager
- ✅ Node.js and npm with common packages
- ✅ SSH configured for Q CLI integration
- ✅ CloudWatch monitoring agent
- ✅ Administrative IAM permissions
- ✅ Automatic dotfile integration for Q CLI

## 🔧 Detailed Usage

### 1. Initial Setup
If you need to recreate SSH keys:
```bash
./setup-ssh-keys.sh
```

### 2. Deploy Infrastructure
```bash
./deploy-spot-qcli-uswest2.sh
```

The script will:
- Delete any existing stack
- Deploy new CloudFormation stack
- Wait for completion
- Display instance details and access commands

### 3. Access Your Instance
Once deployed, you'll get output like:
```
Instance i-0123456789abcdef0 (m5.2xlarge in us-west-2a): Public IP = 1.2.3.4
SSH Command: ssh -i amazon-q-key-uswest2.pem ubuntu@1.2.3.4
SSM Command: aws ssm start-session --target i-0123456789abcdef0 --region us-west-2
```

**SSH with connection options (recommended):**
```bash
ssh -i amazon-q-key-uswest2.pem -o ConnectTimeout=15 -o StrictHostKeyChecking=no ubuntu@<INSTANCE_IP>
```

### 4. Using Amazon Q CLI
After SSH'ing into the instance:
```bash
# Check Q CLI version
q --version

# Start a chat session
q chat

# Get help
q --help
```

## 🛠️ Troubleshooting

### Common Issues

#### SSH Connection Refused
- Wait 2-3 minutes after deployment for instance initialization
- Ensure you're using the correct IP address
- Verify key file permissions: `chmod 600 amazon-q-key-uswest2.pem`
- Use connection timeout options: `ssh -i amazon-q-key-uswest2.pem -o ConnectTimeout=15 -o StrictHostKeyChecking=no ubuntu@<INSTANCE_IP>`

#### Spot Instance Termination
- The mixed instance type configuration reduces termination frequency
- If terminated, the spot fleet will automatically launch a replacement
- Check current instances: `aws ec2 describe-spot-fleet-instances --spot-fleet-request-id <FLEET_ID> --region us-west-2`

#### Q CLI Not Working
- Allow 5-10 minutes for complete installation after instance launch
- Check installation status: `sudo tail -f /var/log/cloud-init-output.log`

### Monitoring Commands
```bash
# Check spot fleet status
aws ec2 describe-spot-fleet-requests --spot-fleet-request-ids <FLEET_ID> --region us-west-2

# View spot fleet history
aws ec2 describe-spot-fleet-request-history --spot-fleet-request-id <FLEET_ID> --region us-west-2

# List active instances
aws ec2 describe-spot-fleet-instances --spot-fleet-request-id <FLEET_ID> --region us-west-2
```

## 💰 Cost Optimization

### Spot Pricing Benefits
- **Cost Savings:** Up to 90% compared to On-Demand pricing
- **Mixed Instance Types:** Reduces interruption risk
- **Multi-AZ Deployment:** Better availability across zones

### Current Configuration
- Max bid: $0.25/hour per instance
- Typical spot prices: $0.15-$0.20/hour
- Expected monthly cost: ~$108-$144 (24/7 usage)

## 🔒 Security Features

### IAM Configuration
- Administrative permissions for development/testing
- **⚠️ Note:** This setup is for non-production use only
- SSM access enabled for secure shell access

### Network Security
- Public subnets with internet gateway
- Security group allows SSH (port 22) from anywhere
- All outbound traffic allowed

### SSH Configuration
- RSA key pair authentication
- Q CLI environment variables accepted
- Stream local forwarding enabled

## 📊 Architecture Components

### AWS Resources Created
- **VPC:** Custom VPC with 4 public subnets
- **Security Groups:** SSH access configuration
- **IAM Roles:** Administrative permissions
- **Spot Fleet:** Mixed instance type configuration
- **Key Pair:** SSH access management

### Software Stack
```
Ubuntu 22.04 LTS
├── Amazon Q CLI (latest)
├── Docker & Docker Compose
├── AWS CLI v2
├── Python 3 + uv package manager
├── Node.js 20 + npm packages
│   ├── TypeScript
│   ├── Vue CLI
│   ├── Angular CLI
│   └── Create React App
└── CloudWatch Agent
```

## 🔄 Maintenance

### Regular Tasks
- Monitor spot instance interruptions
- Update software packages periodically
- Backup important data before instance termination

### Stack Updates
To update the infrastructure:
1. Modify `spot-qcli-template-uswest2.yaml`
2. Run `./deploy-spot-qcli-uswest2.sh`
3. The script handles stack replacement automatically

## 📝 Notes

### Important Considerations
- **Spot Instances:** Can be interrupted with 2-minute notice
- **Data Persistence:** Use EBS volumes or external storage for important data
- **Development Use:** This configuration is optimized for development/testing
- **Region Specific:** Template configured for us-west-2 region

### File Locations on Instance
- Q CLI config: `~/.amazon-q/`
- Docker data: `/var/lib/docker/`
- User data logs: `/var/log/cloud-init-output.log`

## 🆘 Support

### Getting Help
1. Check the troubleshooting section above
2. Review AWS CloudFormation events in the console
3. Examine instance logs via SSH or SSM
4. Check spot fleet request history for interruption patterns

### Useful Log Locations
```bash
# Cloud-init logs (installation progress)
sudo tail -f /var/log/cloud-init-output.log

# System logs
sudo journalctl -f

# Docker logs
sudo docker logs <container_name>
```

---

**Last Updated:** June 2025  
**Version:** 2.0  
**Region:** us-west-2  
**Maintained by:** Infrastructure Team
