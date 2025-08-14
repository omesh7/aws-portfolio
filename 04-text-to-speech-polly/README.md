# Project 04 - Text-to-Speech Polly

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.6.0
- Node.js 18+
- GitHub repository pushed to `omesh7/aws-portfolio`
- GitHub CLI authenticated (for CLI commands)

## 🚀 Quick Start

### Local Development
```bash
# Linux/macOS
./local-dev.sh

# Windows
local-dev.bat
```

### CI/CD Deployment

#### Option 1: GitHub UI
1. Go to GitHub Actions
2. Select "Project 04 - Text-to-Speech Polly"
3. Choose action: `plan`, `apply`, or `destroy`
4. Click "Run workflow"

#### Option 2: GitHub CLI
```bash
# First, ensure you're in the repository directory and it's pushed to GitHub
cd /path/to/aws-portfolio

# Plan infrastructure
gh workflow run project-04-deploy.yml -f action=plan

# Deploy infrastructure
gh workflow run project-04-deploy.yml -f action=apply

# Destroy infrastructure
gh workflow run project-04-deploy.yml -f action=destroy
```

#### Option 3: curl Commands
```bash
# Set your GitHub token and repo details
export GITHUB_TOKEN="your_github_token"
export REPO_OWNER="omesh7"
export REPO_NAME="aws-portfolio"

# Plan infrastructure
curl -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/project-04-deploy.yml/dispatches" \
  -d '{"ref":"main","inputs":{"action":"plan"}}'

# Deploy infrastructure
curl -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/project-04-deploy.yml/dispatches" \
  -d '{"ref":"main","inputs":{"action":"apply"}}'

# Destroy infrastructure
curl -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/project-04-deploy.yml/dispatches" \
  -d '{"ref":"main","inputs":{"action":"destroy"}}'
```

## 📁 Structure
```
04-text-to-speech-polly/
├── infrastructure/
│   ├── main.tf              # Terraform configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── terraform.tfvars     # Local development values
├── lambda/
│   ├── index.js             # Lambda function code
│   └── package.json         # Dependencies
├── local-dev.sh             # Local development (Linux/macOS)
├── local-dev.bat            # Local development (Windows)
└── README.md                # This file
```

## 🏗️ CI/CD Architecture

The GitHub Actions workflow consists of 3 separate jobs:

1. **`build-lambda`**: Installs dependencies and packages Lambda function
2. **`terraform-infrastructure`**: Runs Terraform operations (plan/apply/destroy)
3. **`test-deployment`**: Tests the deployed Lambda function

### Workflow Features
- **Manual trigger only**: Prevents accidental deployments
- **Artifact sharing**: Lambda package passed between jobs
- **Comprehensive testing**: Function URL and AWS CLI tests
- **Proper error handling**: Job dependencies and conditions

## 🔧 Configuration

**Local Environment:**
- Uses `terraform.tfvars` for configuration
- Creates resources with `-local` suffix
- Uses `data.archive_file` for Lambda packaging

**CI Environment:**
- Uses GitHub Actions variables
- Creates resources with `-ci` suffix
- Uses pre-built Lambda zip artifact
- Unique S3 bucket per run: `polly-tts-audio-bucket-ci-{run_number}`

## 🧪 Testing

### Automated Tests (CI)
- Function URL test with default text
- Function URL test with custom text
- AWS CLI invoke test

### Manual Testing
```bash
# Test with default text
curl -X POST "https://your-lambda-url.lambda-url.region.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{}'

# Test with custom text and voice
curl -X POST "https://your-lambda-url.lambda-url.region.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello World!", "voice": "Matthew"}'
```

## 🗑️ Cleanup

**Local:**
```bash
cd infrastructure
terraform destroy -auto-approve
```

**CI:**
```bash
# Using GitHub CLI
gh workflow run project-04-deploy.yml -f action=destroy

# Using curl
curl -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/project-04-deploy.yml/dispatches" \
  -d '{"ref":"main","inputs":{"action":"destroy"}}'
```