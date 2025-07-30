# 🌐 Project 1: Static Portfolio Website on S3

A serverless static website hosting solution using AWS S3 with automated CI/CD deployment pipeline.

## 📋 Overview

This project demonstrates hosting a personal portfolio website built with Vite on AWS S3, featuring automated deployment through GitHub Actions and global content delivery via CloudFront CDN.

## 🏗️ Architecture

```
GitHub Repository → GitHub Actions → AWS S3 → CloudFront → [Optional: Custom Domain]
```

## 🔧 AWS Services Used

- **Amazon S3** - Static website hosting and file storage
- **Amazon CloudFront** - Global CDN for fast content delivery
- **AWS IAM** - Access management and permissions

## 📁 Project Structure

```
01-static-website-s3/
├── site/                    # Vite application source
│   ├── src/                 # Source code
│   ├── public/              # Static assets
│   ├── package.json         # Dependencies
│   └── vite.config.js       # Build configuration
├── terraform/               # Infrastructure as Code
│   ├── main.tf              # S3 bucket and CloudFront setup
│   ├── variables.tf         # Configuration variables
│   └── outputs.tf           # Resource outputs
└── README.md               # This file
```

## ⚙️ Configuration

### Terraform Variables
- S3 bucket name for static hosting
- CloudFront distribution settings

### GitHub Secrets Required
- `AWS_ACCESS_KEY_ID` - AWS access credentials
- `AWS_SECRET_ACCESS_KEY` - AWS secret credentials
- `AWS_REGION` - Target AWS region
- `S3_BUCKET_NAME_STATIC_PROJECT_01` - S3 bucket name
- `VITE_APP_EMAILJS_SERVICE_ID` - EmailJS service ID
- `VITE_APP_EMAILJS_TEMPLATE_ID_PROJECT_01_STATIC_SITE` - EmailJS template
- `VITE_APP_EMAILJS_PUBLIC_KEY` - EmailJS public key

## 🚀 Deployment Process

### 1. Infrastructure Provisioning
- Terraform creates S3 bucket with static website hosting
- CloudFront distribution configured for global delivery

### 2. Automated Deployment
- GitHub Actions triggers on changes to `site/` directory
- Vite builds the static application
- Built files sync to S3 bucket

## 🛠️ Local Development

### Prerequisites
- Node.js 18+
- npm or yarn
- AWS CLI configured

### Setup
```bash
cd 01-static-website-s3/site
npm install
npm run dev
```

### Build
```bash
npm run build
```

## 📝 Features

- **Responsive Design** - Mobile-first approach
- **Fast Loading** - Optimized with Vite bundling
- **Global CDN** - CloudFront for worldwide delivery
- **Contact Form** - EmailJS integration
- **CI/CD Pipeline** - Automated deployments

## 🔄 Workflow Triggers

The deployment workflow runs on:
- Push to `main` branch with changes in `01-static-website-s3/site/**`
- Manual trigger via `workflow_dispatch`

## 📊 Monitoring

- **CloudFront Metrics** - Request count, cache hit ratio
- **S3 Metrics** - Storage usage, request metrics

## 💰 Cost Optimization

- S3 static hosting (minimal cost)
- CloudFront free tier eligible
- No additional DNS or SSL costs

## 🔒 Security Features

- S3 bucket policies restrict direct access
- IAM roles with minimal required permissions
- No server-side components to secure

## 🌍 Custom Domain Setup Options

### Option 1: Cloudflare Integration (Recommended)
1. Add CNAME record in Cloudflare DNS:
   ```
   Type: CNAME
   Name: portfolio (or subdomain of choice)
   Target: your-cloudfront-domain.cloudfront.net
   ```
2. Enable Cloudflare SSL (Full or Flexible)
3. Configure page rules for caching optimization
4. Benefits: Free SSL, additional CDN layer, DDoS protection

### Option 2: Direct CloudFront Access
- Use the default CloudFront domain: `https://d1234567890.cloudfront.net`
- No additional configuration required
- Good for testing and development

### Option 3: AWS Route 53 + ACM (Advanced)
- Create Route 53 hosted zone
- Request ACM certificate
- Configure CloudFront with custom domain
- Additional cost: ~$0.50/month for hosted zone

## 📈 Performance

- **Global Edge Locations** - CloudFront CDN
- **Optimized Assets** - Vite build optimization
- **Compressed Files** - Gzip/Brotli compression
- **Browser Caching** - Configured cache headers

## 🔧 Troubleshooting

### Common Issues
- **Build Failures** - Check Node.js version and dependencies
- **S3 Sync Errors** - Verify AWS credentials and bucket permissions
- **CloudFront Delays** - Distribution updates can take 15-20 minutes
- **Cloudflare SSL Issues** - Ensure SSL mode is set to "Full" or "Flexible"

### Debug Commands
```bash
# Test local build
npm run build && npm run preview

# Check AWS credentials
aws sts get-caller-identity

# Verify S3 bucket
aws s3 ls s3://your-bucket-name
```

## 📚 Additional Resources

- [AWS S3 Static Website Hosting Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Vite Build Guide](https://vitejs.dev/guide/build.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)