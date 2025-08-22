# 🌐 Project 01 - Static Website on AWS

A production-ready static website hosting solution using AWS S3, CloudFront, and optional Cloudflare integration. Built with modern Vite + React and deployed via Terraform Infrastructure as Code.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Vite + React  │───▶│  S3 Static Site  │───▶│   CloudFront    │
│     Frontend    │    │     Hosting      │    │      CDN        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
                                               ┌─────────────────┐
                                               │   Cloudflare    │
                                               │  (Optional DNS) │
                                               └─────────────────┘
```

## 🚀 Features

- **Modern Frontend**: Vite + React 19 with Three.js animations
- **AWS Infrastructure**: S3 + CloudFront with Origin Access Control
- **Custom Domain**: Optional Cloudflare DNS integration
- **SSL/TLS**: Automatic HTTPS with ACM certificates
- **CI/CD Ready**: GitHub Actions workflow included
- **Local Development**: Easy local deployment scripts
- **Cost Optimized**: Serverless architecture (<$5/month)

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.6.0
- Node.js 18+ and npm
- (Optional) Cloudflare account for custom domain

## 🛠️ Quick Start

### Local Deployment

1. **Clone and navigate to project**:
   ```bash
   git clone <repository-url>
   cd 01-static-website-s3
   ```

2. **Configure Terraform variables**:
   ```bash
   cd infrastructure
   cp secrets.auto.tfvars.example secrets.auto.tfvars
   # Edit secrets.auto.tfvars with your values
   ```

3. **Deploy with script**:
   ```bash
   # Windows
   deploy-local.bat
   
   # Linux/macOS
   chmod +x deploy-local.sh
   ./deploy-local.sh
   ```

### Manual Deployment

1. **Build the site**:
   ```bash
   cd site
   npm install
   npm run build
   ```

2. **Deploy infrastructure**:
   ```bash
   cd ../infrastructure
   terraform init
   terraform apply -var="environment=local" -var="upload_site_files=true"
   ```

## ⚙️ Configuration

### Terraform Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `project_name` | Project identifier | `01-static-website-aws-portfolio` | No |
| `aws_region` | AWS region | `ap-south-1` | No |
| `environment` | Environment (local/ci) | `local` | No |
| `enable_custom_domain` | Enable Cloudflare domain | `false` | No |
| `cloudflare_api_token` | Cloudflare API token | `""` | If using custom domain |
| `cloudflare_zone_id` | Cloudflare zone ID | `""` | If using custom domain |
| `subdomain` | Subdomain name | `portfolio` | No |
| `upload_site_files` | Upload files via Terraform | `false` | No |

### Environment-Specific Behavior

- **Local Environment** (`environment=local`):
  - Can upload site files directly via Terraform
  - Uses local build artifacts
  - Simplified configuration

- **CI Environment** (`environment=ci`):
  - Files deployed via GitHub Actions
  - Separate build and deploy stages
  - Production optimizations

## 🔧 Development

### Site Development

```bash
cd site
npm install
npm run dev     # Start development server
npm run build   # Build for production
npm run preview # Preview production build
```

### Infrastructure Development

```bash
cd infrastructure
terraform init
terraform plan                    # Preview changes
terraform apply                   # Apply changes
terraform destroy                 # Clean up resources
```

## 🚀 CI/CD Deployment

The project includes a GitHub Actions workflow for automated deployment:

### Required Secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `CLOUDFLARE_API_TOKEN` (optional)
- `CLOUDFLARE_ZONE_ID` (optional)

### Workflow Usage

1. Go to Actions tab in GitHub
2. Select "Project 01 - Static Website"
3. Click "Run workflow"
4. Choose action: `deploy` or `destroy`

## 📊 Outputs

After deployment, Terraform provides:

- `s3_bucket_name`: S3 bucket hosting the site
- `cloudfront_distribution_id`: CloudFront distribution ID
- `cloudfront_domain`: CloudFront domain name
- `website_url`: Final website URL

## 💰 Cost Estimation

**Monthly costs (approximate)**:
- S3 Storage: $0.023/GB
- CloudFront: $0.085/GB (first 10TB)
- ACM Certificate: Free
- Route 53 (if used): $0.50/hosted zone

**Total**: ~$2-5/month for typical usage

## 🔒 Security Features

- **Origin Access Control**: S3 bucket only accessible via CloudFront
- **HTTPS Enforced**: All traffic redirected to HTTPS
- **Security Headers**: CloudFront security configurations
- **IAM Least Privilege**: Minimal required permissions

## 🧹 Cleanup

To destroy all resources:

```bash
# Local
cd infrastructure
terraform destroy

# CI/CD
# Use GitHub Actions with "destroy" action
```

## 📚 Tech Stack

- **Frontend**: Vite, React 19, Three.js, Tailwind CSS
- **Infrastructure**: Terraform, AWS S3, CloudFront, ACM
- **DNS**: Cloudflare (optional)
- **CI/CD**: GitHub Actions
- **Monitoring**: CloudWatch (built-in)

## 🔗 Related Projects

This project follows the same patterns as:
- [Project 06 - Smart Image Resizer](../06-smart-resize-images/)
- [Project 14 - Multi-Cloud Weather Tracker](../14-multicloud-weather-tracker/)

## 📝 License

This project is part of the AWS Portfolio collection. See the main repository for license details.