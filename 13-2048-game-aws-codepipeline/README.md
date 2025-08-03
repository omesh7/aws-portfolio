# 2048 Game - CI/CD Pipeline with AWS

A complete 2048 game implementation with automated CI/CD pipeline using AWS services, demonstrating modern DevOps practices and cloud-native architecture.

## 🎯 Project Overview

**Tech Stack:**

- **Backend:** Python Flask API with game logic
- **Frontend:** React + Vite with responsive design
- **CI/CD:** AWS CodePipeline with separate backend/frontend builds
- **Infrastructure:** Terraform for complete automation
- **Deployment:** ECS Fargate + S3 Static Hosting

**Live Demo:**

- Frontend: http://project-13-2048-game-codepp-frontend.s3-website.ap-south-1.amazonaws.com
- API: http://project-13-2048-game-codepp-alb-218907064.ap-south-1.elb.amazonaws.com

## 🏗️ Architecture

```
GitHub → CodePipeline → {
  ├── Backend Build → Docker → ECR → ECS Fargate → ALB
  └── Frontend Build → React → S3 Static Website
}
```

**Key Components:**

- **ECS Fargate:** Serverless container hosting for Flask API
- **Application Load Balancer:** Traffic distribution and health checks
- **S3 Static Website:** React frontend hosting
- **ECR:** Container image registry
- **CodePipeline:** Automated CI/CD with separate build stages
- **Terraform:** Infrastructure as Code

## 📁 Project Structure

```
13-2048-game-aws-codepipeline/
├── README.md                    # This file
├── DEPLOYMENT-GUIDE.md          # Step-by-step deployment
├── app.py                       # Flask API with 2048 game logic
├── requirements.txt             # Python dependencies
├── buildspec/                   # CodeBuild specifications
│   ├── backend-buildspec.yml    # Backend build configuration
│   └── frontend-buildspec.yml   # Frontend build configuration
├── docker/
│   └── Dockerfile              # Container configuration
├── frontend/                   # React application
│   ├── src/
│   │   ├── App.jsx             # Main application
│   │   └── components/
│   │       └── Game2048.jsx    # Game component
│   ├── package.json            # Frontend dependencies
│   └── vite.config.js          # Build configuration
├── infrastructure/             # Terraform configuration
│   ├── main.tf                 # Core AWS resources
│   ├── codepipeline.tf         # CI/CD pipeline
│   ├── variables.tf            # Configuration variables
│   ├── outputs.tf              # Infrastructure outputs
│   └── terraform.tfvars.example # Configuration template
└── scripts/                    # Management scripts
    ├── run.sh / run.bat        # Cross-platform runners
    ├── linux/                  # Linux/macOS scripts
    └── windows/                # Windows scripts
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- Docker Desktop
- Node.js >= 18
- Python 3.11+

### 1. Clone and Configure

```bash
git clone <your-repo>
cd 13-2048-game-aws-codepipeline

# Configure Terraform
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Deploy Infrastructure

```bash
# Cross-platform
./scripts/run.sh deploy     # Linux/macOS
.\scripts\run.bat deploy    # Windows

# Platform-specific
./scripts/linux/deploy.sh   # Linux/macOS
.\scripts\windows\deploy.bat # Windows
```

### 3. Monitor Deployment

```bash
./scripts/run.sh status
```

## 🔄 CI/CD Pipeline

The pipeline automatically triggers on GitHub pushes with two parallel build stages:

### Backend Build (`buildspec/backend-buildspec.yml`)

1. **Docker Build:** Creates container image from Flask app
2. **ECR Push:** Stores image in container registry
3. **ECS Deploy:** Updates Fargate service with new image

### Frontend Build (`buildspec/frontend-buildspec.yml`)

1. **Environment Setup:** Creates `.env` with dynamic API URL
2. **React Build:** Compiles frontend with Vite
3. **S3 Deploy:** Syncs build artifacts to static website

## 🎮 Game Features

- **Complete 2048 Logic:** Merge tiles to reach 2048
- **Responsive Design:** Works on desktop and mobile
- **Keyboard Controls:** Arrow keys for movement
- **Touch Support:** Mobile swipe gestures
- **Real-time Score:** Live score updates
- **Game State Management:** Persistent game state

## 🛠️ Management Scripts

```bash
# Deploy everything
./scripts/run.sh deploy

# Check status
./scripts/run.sh status

# Trigger manual build
./scripts/run.sh trigger-build

# Test deployment
./scripts/run.sh test-deployment

# Clean up resources
./scripts/run.sh destroy
```

## 📊 Infrastructure Details

**Estimated Monthly Cost:** ~$33-42

- ECS Fargate: ~$15-20
- Application Load Balancer: ~$16
- S3 + ECR + CodePipeline: ~$2-6

**Performance:**

- API Response: <100ms
- Concurrent Users: 1000+
- Auto-scaling: CPU/memory based
- Availability: 99.9% uptime

## 🔧 Development

### Local Development

```bash
# Backend
pip install -r requirements.txt
python app.py

# Frontend
cd frontend
npm install
npm run dev

# Docker
docker build -f docker/Dockerfile -t 2048-game .
docker run -p 8080:8080 2048-game
```

### Testing

```bash
# API health check
curl http://localhost:8080/

# Create new game
curl -X POST http://localhost:8080/ \
  -H "Content-Type: application/json" \
  -d '{"action":"new"}'
```

## 🔍 Troubleshooting

### Common Issues

**Pipeline Build Fails:**

```bash
# Check CodeBuild logs
aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild"
```

**Frontend "Failed to fetch" Error:**

- Check if API URL is correct in browser console
- Verify ECS service is healthy
- Check CORS configuration

**ECS Service Issues:**

```bash
# Check service status
aws ecs describe-services --cluster <cluster> --services <service>

# Check logs
aws logs tail "/ecs/project-name" --follow
```

## 📚 Documentation

- **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Complete deployment instructions
- **[Terraform Files](infrastructure/)** - Infrastructure documentation
- **[Build Specs](buildspec/)** - CI/CD configuration details

## 🎯 Learning Outcomes

This project demonstrates:

- **DevOps:** Complete CI/CD pipeline automation
- **Containers:** Docker + ECS Fargate orchestration
- **Infrastructure as Code:** Terraform best practices
- **Full-Stack Development:** React + Flask integration
- **AWS Services:** 8+ services working together
- **Security:** Cloud security best practices

## 🧹 Cleanup

```bash
# Destroy all resources
./scripts/run.sh destroy
```

**⚠️ Important:** This will delete all AWS resources and cannot be undone.

---

**Built with ❤️ using AWS, Docker, React, Flask, and Terraform**
