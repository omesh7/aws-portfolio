# Terraform Infrastructure - Text-to-Speech Polly

## Quick Deploy

```bash
# Navigate to infrastructure
cd infrastructure/

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

## Resources Created

- **Lambda Function**: `polly-text-to-speech`
- **Lambda Function URL**: HTTPS endpoint with CORS
- **S3 Bucket**: Audio file storage with public access
- **IAM Role**: Lambda execution permissions
- **CloudWatch**: Logging and monitoring

## Outputs

- `lambda_function_url`: Direct Lambda endpoint for text-to-speech
- `s3_bucket_name`: Bucket name for audio files
- `lambda_function_name`: Lambda function name