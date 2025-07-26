# YouTube Summarizer - AWS Fargate Deployment

A scalable FastAPI application for summarizing YouTube videos using AI models, deployed on AWS Fargate with Terraform.

## 📁 Project Structure

```
12-kubernetes-simple-app/
├── app/                    # Application code
│   ├── main.py            # FastAPI application
│   ├── requirements.txt   # Python dependencies
│   └── .env              # Environment variables
├── docker/                # Docker configuration
│   └── Dockerfile        # Container definition
├── scripts/               # Deployment scripts
│   ├── build-and-push.ps1    # Build and push to ECR
│   └── cleanup-fargate.ps1   # Clean up AWS resources
├── infrastructure/        # Terraform infrastructure
│   ├── main.tf           # Main Terraform configuration
│   ├── terraform.tfvars.example  # Variables example
│   └── deploy.ps1        # Terraform deployment script
└── README.md             # This file
```

## 🚀 Features

- **4 AI Models**: Gemini, Groq, OpenAI, AWS Bedrock
- **Browser-Friendly**: GET endpoints with WebSocket streaming
- **Cost-Efficient**: Uses cheapest models (Claude 3 Haiku, Llama 3 8B, etc.)
- **Free Tier Compatible**: Designed for AWS free tier usage
- **Auto-Scaling**: ECS Fargate with load balancer
- **Infrastructure as Code**: Complete Terraform setup

## 🛠️ Quick Deployment

### 1. Setup Infrastructure with Terraform

```powershell
# Navigate to infrastructure folder
cd infrastructure

# Copy and edit variables
copy secrets.auto.tfvars.example secrets.auto.tfvars
# Edit secrets.auto.tfvars with your API keys

# Deploy infrastructure
.\deploy.ps1 apply
```

### 2. Build and Deploy Application

```powershell
# Navigate to scripts folder
cd ../scripts

# Build and push Docker image (get account ID from AWS console)
.\build-and-push.ps1 -AccountId "123456789012"
```

### 3. Access Your Application

After deployment, Terraform will output the load balancer URL:

```
http://your-alb-dns.us-east-1.elb.amazonaws.com/summarize?url=dQw4w9WgXcQ
```

## 🔧 API Endpoints

- `GET /` - API information
- `GET /models` - Available AI models
- `POST /summarize` - Summarize video (JSON)
- `GET /summarize?url=VIDEO_URL` - Browser-friendly summarization
- `WebSocket /ws/{video_id}` - Real-time progress streaming

## 💰 Cost Optimization

- **Fargate**: 20GB-hours/month free
- **ECR**: 500MB storage free
- **CloudWatch**: 5GB logs free
- **Load Balancer**: ~$16/month (only paid component)
- **AI Models**: Pay-per-use, very cost-effective

## 🧹 Cleanup

To avoid charges, clean up resources:

```powershell
# Clean up AWS resources
cd infrastructure
.\deploy.ps1 destroy

# Or use the cleanup script
cd ../scripts
.\cleanup-fargate.ps1 -AccountId "123456789012"
```

## 🔑 Required API Keys

Add these to `infrastructure/secrets.auto.tfvars`:

- `gemini_api_key` - Google AI Studio (free tier available)
- `groq_api_key` - Groq (free tier available)
- `openai_api_key` - OpenAI (optional)

AWS Bedrock access is automatic with your AWS credentials.

## 📝 Example Usage

### Browser Testing
```
http://your-url/summarize?url=https://www.youtube.com/watch?v=dQw4w9WgXcQ&model=bedrock&mode=bullet
```

### API Testing
```bash
curl -X POST "http://your-url/summarize" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "language": "English",
    "mode": "concise",
    "model": "gemini"
  }'
```

## 🏗️ Architecture

- **AWS Fargate**: Serverless container hosting
- **Application Load Balancer**: Traffic distribution
- **ECR**: Container registry
- **Parameter Store**: Secure API key storage
- **CloudWatch**: Logging and monitoring
- **VPC**: Network isolation

Perfect for portfolio demonstrations with professional AWS deployment! 🎉