# Project 06 - Smart Image Resizer Deployment

## GitHub CLI Commands

### Prerequisites
- GitHub CLI authenticated: `gh auth login`
- Repository pushed to GitHub: `omesh7/aws-portfolio`

### Deployment Commands

#### Deploy Everything (AWS + Vercel)
```bash
gh workflow run project-06-deploy.yml -f action=deploy
```

#### Destroy Everything (AWS + Vercel)
```bash
gh workflow run project-06-deploy.yml -f action=destroy
```

### Required GitHub Secrets

#### AWS Secrets
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

#### Vercel Secrets
- `VERCEL_TOKEN` - Vercel API token
- `VERCEL_ORG_ID` - Vercel organization ID
- `VERCEL_PROJECT_ID` - Vercel project ID

### Architecture

**AWS Backend:**
- Lambda function with Sharp image processing
- API Gateway for HTTP endpoints
- S3 bucket for processed images
- IAM roles and policies

**Vercel Frontend:**
- Next.js 15 application
- React 19 with TypeScript
- Tailwind CSS + shadcn/ui
- Fallback to local Sharp processing

### Workflow Jobs

1. **build-lambda** - Packages Lambda function with dependencies
2. **terraform-infrastructure** - Deploys AWS resources
3. **deploy-vercel-site** - Deploys Next.js app to Vercel
4. **test-deployment** - Tests Lambda endpoints

### Environment Variables

The Vercel deployment automatically receives:
- `IMAGE_RESIZE_API_URL` - API Gateway endpoint from Terraform output