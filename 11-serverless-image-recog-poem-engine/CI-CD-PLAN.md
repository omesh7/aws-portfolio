# Project 11 CI/CD Deployment Plan

## 📋 Project Analysis

**Project Type:** Serverless Image Recognition + AI Poetry Generation
**Key Components:**
- 2 Lambda functions (upload handler + image processor)
- S3 bucket with event triggers
- AWS Rekognition for image analysis
- AWS Bedrock for AI poem generation
- Terraform infrastructure

## 🏗️ Architecture Flow

```
User Upload → S3 Bucket → Lambda Trigger → Rekognition → Bedrock → Poem Storage
     ↑                                                                    ↓
Upload Lambda (Presigned URLs) ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←← Cleanup
```

## 🚀 CI/CD Pipeline Jobs

### Job 1: `package-lambda-functions`
**Purpose:** Package both Lambda functions into zip files
**Dependencies:** None
**Actions:**
- Checkout code
- Setup Python 3.12
- Package upload Lambda → `lambda_upload.zip`
- Package image_recog Lambda → `lambda_image_recog.zip`
- Upload both as artifacts

### Job 2: `deploy-infrastructure`
**Purpose:** Deploy all AWS resources using Terraform
**Dependencies:** `package-lambda-functions`
**Actions:**
- Checkout code
- Download Lambda artifacts
- Setup Terraform
- Deploy infrastructure (S3, IAM, Lambda functions, triggers)
- Capture outputs (bucket name, function URLs)

### Job 3: `destroy-infrastructure` (conditional)
**Purpose:** Clean up all resources when action = 'destroy'
**Dependencies:** None (runs independently)
**Actions:**
- Checkout code
- Setup Terraform
- Destroy all resources

## 🔧 Key Differences from Project 10

| Aspect | Project 10 | Project 11 |
|--------|------------|------------|
| **Containers** | Docker + ECR | None |
| **Lambda Functions** | 1 function | 2 functions |
| **AI Services** | None | Rekognition + Bedrock |
| **Triggers** | Manual/Kinesis | S3 Events |
| **Complexity** | High (multi-stage) | Medium (simpler) |

## 📦 Terraform Resources

**Infrastructure includes:**
- S3 bucket with lifecycle rules
- 2 Lambda functions with different roles
- IAM policies for Rekognition + Bedrock
- S3 event notifications
- Lambda function URLs with CORS
- CloudWatch logging

## 🎯 Deployment Variables

**Required Terraform Variables:**
- `project_name` - Unique identifier
- `aws_region` - Deployment region
- `bedrock_model_id` - AI model selection

**Environment Variables for Lambda:**
- `BUCKET_NAME` - S3 bucket name
- `BEDROCK_MODEL_ID` - AI model ID
- `LOG_LEVEL` - Logging level

## ⚡ Simplified Pipeline (vs Project 10)

**Project 10 Flow:**
```
ECR Setup → Docker Build → Lambda Package → Infrastructure → Cleanup
```

**Project 11 Flow:**
```
Lambda Package → Infrastructure Deploy/Destroy
```

## 🔍 Testing Strategy

**Manual Testing Commands:**
```bash
# Test upload function
curl -X POST https://lambda-url/upload -d '{"fileName":"test.jpg"}'

# Test image processing (upload image to S3)
aws s3 cp test-image.jpg s3://bucket-name/uploads/

# Check generated poems
aws s3 ls s3://bucket-name/poems/
```

## 📝 GitHub Actions Structure

```yaml
name: Project 11 - Serverless Image Recognition Poem Engine

on:
  workflow_dispatch:
    inputs:
      action: [deploy, destroy]

env:
  AWS_REGION: "ap-south-1"
  PROJECT_NAME: "11-serverless-image-recog-poem"

jobs:
  package-lambda-functions:    # Package both Lambda functions
  deploy-infrastructure:       # Deploy via Terraform
  destroy-infrastructure:      # Cleanup (conditional)
```

## 🎯 Success Criteria

**Deployment Success:**
- ✅ Both Lambda functions deployed
- ✅ S3 bucket created with proper triggers
- ✅ Upload function returns presigned URLs
- ✅ Image processing generates poems
- ✅ Automatic cleanup works

**Testing Success:**
- ✅ Upload image → poem generated
- ✅ Multiple images processed
- ✅ Error handling works
- ✅ Cleanup removes uploaded images

This is a much simpler pipeline than Project 10 - no Docker, no ECR, just Lambda packaging and Terraform deployment!