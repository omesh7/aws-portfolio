# AWS Portfolio - Standardized Naming Convention

## Overview
All AWS resources across the 14 portfolio projects now use random hex suffixes to ensure unique naming and prevent conflicts during deployment.

## Naming Pattern
```
{resource-base-name}-{random-hex-suffix}
```

Where:
- `resource-base-name`: Descriptive name based on project and resource type
- `random-hex-suffix`: 4-byte (8-character) random hexadecimal string

## Implementation

### Random ID Generation
Each project uses Terraform's `random_id` or `random_string` resource:

```hcl
# For most projects
resource "random_id" "resource_suffix" {
  byte_length = 4  # Generates 8-character hex string
}

# For Project 13 (existing pattern)
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
```

### Resource Naming Examples

#### S3 Buckets
```hcl
# Before: bucket = "static-website-bucket"
# After:  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}"
# Result: "01-project-aws-portfolio-a1b2c3d4"
```

#### Lambda Functions
```hcl
# Before: function_name = "polly-tts-function"
# After:  function_name = "${var.project_name}-polly-tts-${random_id.resource_suffix.hex}"
# Result: "04-text-to-speech-polly-polly-tts-a1b2c3d4"
```

#### DynamoDB Tables
```hcl
# Before: name = "receipts-table"
# After:  name = "${var.dynamodb_table_name}-${random_id.resource_suffix.hex}"
# Result: "Receipts-a1b2c3d4"
```

## Project Status

### ✅ Implemented Projects

| Project | Resources with Random Suffixes | Status |
|---------|--------------------------------|--------|
| **01** - Static Website S3 | S3 bucket | ✅ Complete |
| **04** - Text-to-Speech Polly | S3 bucket | ✅ Complete |
| **06** - Smart Image Resizer | S3 bucket | ✅ Complete |
| **07** - Receipt Processor | S3 bucket, DynamoDB table | ✅ Complete |
| **08** - AI RAG Chat | S3 bucket (in module) | ✅ Complete |
| **10** - Kinesis ECR ML | Kinesis stream, DynamoDB table | ✅ Complete |
| **11** - Image Recognition Poetry | S3 bucket (already implemented) | ✅ Complete |
| **12** - Kubernetes App | ECR repository, VPC, IAM roles | ✅ Complete |
| **13** - 2048 Game CodePipeline | All resources (already implemented) | ✅ Complete |
| **14** - Multi-cloud Weather | S3 bucket, Lambda function, IAM role | ✅ Complete |

### ⚠️ No Infrastructure Projects
| Project | Type | Reason |
|---------|------|--------|
| **02** - Mass Email Lambda | Lambda-only | No Terraform infrastructure |
| **03** - Custom Alexa Skill | Alexa Skill | Manual deployment via Alexa Console |
| **05** - Content Recommendation | Python ML | Local execution, no AWS resources |
| **09** - Lex Chatbot | README-only | Not implemented yet |

## Benefits

### 1. **Conflict Prevention**
- Eliminates naming conflicts when multiple developers deploy
- Allows multiple environments (dev, staging, prod) in same AWS account
- Prevents "bucket already exists" errors

### 2. **Deployment Flexibility**
- Each deployment gets unique resource names
- Safe to deploy multiple instances for testing
- Easy cleanup without affecting other deployments

### 3. **Multi-Environment Support**
- Same Terraform code works across environments
- No need for environment-specific naming variables
- Consistent naming pattern across all projects

### 4. **Security & Isolation**
- Resources are uniquely identifiable
- Reduces risk of accidental resource access
- Clear ownership and traceability

## Usage Guidelines

### For New Projects
1. Add `random` provider to `providers.tf`:
```hcl
random = {
  source  = "hashicorp/random"
  version = "~> 3.1"
}
```

2. Create random ID resource:
```hcl
resource "random_id" "resource_suffix" {
  byte_length = 4
}
```

3. Apply suffix to all resources requiring unique names:
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "${var.project_name}-${random_id.resource_suffix.hex}"
}
```

### For Existing Projects
- All projects have been updated with random suffixes
- No manual intervention required
- Next `terraform apply` will create resources with new names

## Terraform State Management

### Important Notes
- Random suffixes are stored in Terraform state
- Destroying and recreating will generate new suffixes
- Use `terraform import` if you need to manage existing resources

### State File Locations
All projects use centralized S3 backend:
```hcl
backend "s3" {
  bucket         = "aws-portfolio-terraform-state"
  key            = "{project-name}/terraform.tfstate"
  region         = "ap-south-1"
  dynamodb_table = "aws-portfolio-terraform-locks"
  encrypt        = true
}
```

## Monitoring & Troubleshooting

### Common Issues
1. **Resource Already Exists**: Random suffix should prevent this
2. **Name Too Long**: AWS has limits (63 chars for S3), monitor total length
3. **Invalid Characters**: Ensure base names follow AWS naming rules

### Verification
Check resource names in AWS Console or CLI:
```bash
# List S3 buckets with project prefix
aws s3 ls | grep "01-project-aws-portfolio"

# List Lambda functions with project prefix  
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `04-text-to-speech-polly`)].FunctionName'
```

## Future Enhancements

### Planned Improvements
1. **Consistent Suffix Length**: Standardize all projects to use 4-byte random_id
2. **Naming Validation**: Add validation rules for resource name lengths
3. **Resource Tagging**: Include random suffix in resource tags for tracking
4. **Documentation**: Auto-generate resource inventory with actual names

### Migration Strategy
- Current implementation is backward compatible
- No immediate action required for existing deployments
- New deployments will automatically use random suffixes

---

**Last Updated**: January 2025  
**Maintainer**: AWS Portfolio Team  
**Version**: 1.0