# 2048 Game CI/CD Pipeline - Scripts

This folder contains deployment and management scripts for both Linux/macOS and Windows platforms.

## 📁 Folder Structure

```
scripts/
├── linux/                 # Linux/macOS scripts
│   ├── deploy.sh          # Complete deployment script
│   ├── destroy.sh         # Complete cleanup script
│   ├── status.sh          # Status monitoring script
├── windows/               # Windows scripts
│   ├── deploy.bat         # Complete deployment script
│   ├── destroy.bat        # Complete cleanup script
│   └── status.bat         # Status monitoring script
├── run.sh                 # Cross-platform runner (Linux/macOS)
├── run.bat                # Windows runner
└── README.md              # This file
```

## 🚀 Quick Start

### Option 1: Use Platform-Specific Scripts

**Linux/macOS:**
```bash
# Deploy
./scripts/linux/deploy.sh

# Check status
./scripts/linux/status.sh

# Cleanup
./scripts/linux/destroy.sh
```

**Windows:**
```cmd
REM Deploy
.\scripts\windows\deploy.bat

REM Check status
.\scripts\windows\status.bat

REM Cleanup
.\scripts\windows\destroy.bat
```

### Option 2: Use Cross-Platform Runners

**Linux/macOS:**
```bash
# Interactive menu
./scripts/run.sh

# Direct action
./scripts/run.sh deploy
./scripts/run.sh status
./scripts/run.sh destroy
```

**Windows:**
```cmd
REM Interactive menu
.\scripts\run.bat

REM Direct action
.\scripts\run.bat deploy
.\scripts\run.bat status
.\scripts\run.bat destroy
```

## 📋 Prerequisites

### Linux/macOS
- AWS CLI v2
- Terraform >= 1.0
- Docker
- Node.js >= 16
- Python 3.x
- curl
- bash

### Windows
- AWS CLI v2
- Terraform >= 1.0
- Docker Desktop
- Node.js >= 16
- Python 3.x
- curl (or PowerShell equivalent)
- Command Prompt or PowerShell

## 🔧 Script Functions

### Deploy Scripts
- ✅ Check prerequisites
- 🧪 Test local development environment
- 🐳 Build and test Docker container
- 🏗️ Deploy Terraform infrastructure
- 📦 Push container to ECR
- ⏳ Wait for service health
- 🧪 Test API endpoints
- 🎨 Build and deploy frontend
- ✅ Final verification

### Status Scripts
- 📊 Show infrastructure status
- 🐳 Check ECS service health
- ⚖️ Monitor load balancer targets
- 🔗 Test API health
- 🎨 Verify frontend deployment
- 🔄 Show CodePipeline status
- 🔨 Display recent builds
- 💰 Show cost estimates
- 🛠️ Provide quick action commands

### Destroy Scripts
- ⚠️ Safety confirmation prompt
- 🛑 Gracefully stop ECS services
- 🗑️ Empty S3 buckets
- 🐳 Delete ECR images
- ⏸️ Stop CodePipeline executions
- 💥 Destroy Terraform infrastructure
- 🧹 Clean up local files and Docker images
- 🔍 Final verification

## 🔒 Safety Features

- **Confirmation prompts** for destructive operations
- **Prerequisite checks** before deployment
- **Graceful service shutdown** during cleanup
- **Resource verification** after operations
- **Error handling** with meaningful messages
- **Backup of original scripts** for reference

## 💡 Tips

1. **First-time setup**: Use the deploy script to set up everything
2. **Regular monitoring**: Use status script to check health
3. **Development workflow**: Make changes and push to trigger CI/CD
4. **Cost management**: Use destroy script when not needed
5. **Troubleshooting**: Check the quick actions in status output

## 🆘 Troubleshooting

### Common Issues

**Permission denied (Linux/macOS):**
```bash
chmod +x scripts/linux/*.sh
chmod +x scripts/run.sh
```

**AWS credentials not configured:**
```bash
aws configure
```

**Docker not running:**
- Start Docker Desktop
- Verify with: `docker --version`

**Terraform state issues:**
- Check `infrastructure/terraform.tfvars` exists
- Verify AWS permissions for Terraform

### Getting Help

1. Check the status script output for diagnostics
2. Review AWS Console for resource status
3. Check CloudWatch logs for application errors
4. Verify all prerequisites are installed

## 📈 Cost Optimization

The status script shows estimated monthly costs (~$33-42). To minimize costs:

1. **Use destroy script** when not actively developing
2. **Monitor usage** through AWS billing dashboard
3. **Consider smaller instance sizes** for development
4. **Clean up unused resources** regularly

## 🔄 CI/CD Workflow

1. Make code changes
2. Push to GitHub repository
3. CodePipeline automatically triggers
4. CodeBuild builds and tests
5. ECS service updates with new container
6. Monitor via status script

---

**Happy coding! 🎉**