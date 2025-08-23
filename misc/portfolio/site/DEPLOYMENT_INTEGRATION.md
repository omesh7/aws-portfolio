# GitHub Actions Deployment Integration

This portfolio site now includes real-time GitHub Actions integration for deploying and managing AWS projects directly from the web interface.

## Features

### 🚀 Real-Time Deployment Management
- **Deploy/Destroy Actions**: Trigger GitHub Actions workflows with a single click
- **Live Status Monitoring**: Real-time status updates with progress tracking
- **Step-by-Step Progress**: See exactly which deployment step is currently running
- **Auto-Refresh**: Automatic polling for active deployments

### 📊 Deployment Dashboard
- **Centralized Control**: Manage all deployable projects from one interface
- **Status Overview**: Quick stats on active, completed, and failed deployments
- **Project Categories**: Separate views for deployable vs manual projects
- **Batch Operations**: Monitor multiple deployments simultaneously

### 🔄 Workflow Integration
- **GitHub Actions**: Direct integration with existing workflow files
- **Workflow Dispatch**: Trigger deployments via `workflow_dispatch` events
- **Status Mapping**: Real-time status from GitHub Actions API
- **Error Handling**: Comprehensive error reporting and recovery

## Setup Instructions

### 1. GitHub Personal Access Token

Create a GitHub Personal Access Token with the following permissions:
- `repo` (Full control of private repositories)
- `workflow` (Update GitHub Action workflows)
- `actions:read` (Read access to actions and workflows)

### 2. Environment Variables

Add to your `.env.local` file:

```bash
# GitHub API Configuration
NEXT_PUBLIC_GITHUB_TOKEN=your_github_personal_access_token_here
NEXT_PUBLIC_GITHUB_REPO_OWNER=omesh7
NEXT_PUBLIC_GITHUB_REPO_NAME=aws-portfolio
```

### 3. Workflow Requirements

Each deployable project must have a corresponding GitHub Actions workflow file in `.github/workflows/` with:

- `workflow_dispatch` trigger
- `action` input parameter (`deploy` or `destroy`)
- Proper job names and step identification

Example workflow structure:
```yaml
name: Project Deploy
on:
  workflow_dispatch:
    inputs:
      action:
        description: 'Action to perform'
        required: true
        type: choice
        options: ['deploy', 'destroy']
        default: 'deploy'

jobs:
  deploy:
    if: inputs.action == 'deploy'
    # ... deployment steps
  
  destroy:
    if: inputs.action == 'destroy'
    # ... destruction steps
```

## Components

### DeploymentStatus
Compact deployment status component for project cards:
- Real-time status badges
- Progress indicators
- Quick action buttons
- Error display

### DeploymentManager
Full-featured deployment management component:
- Detailed status information
- Complete action controls
- Live URL access
- Comprehensive error handling

### DeploymentDashboard
Centralized dashboard for all projects:
- Status overview cards
- Tabbed project views
- Bulk status refresh
- Real-time monitoring

### useWorkflowStatus Hook
Custom React hook for workflow management:
- Status polling
- Action triggering
- Error handling
- Automatic refresh logic

## Project Mapping

Projects are mapped to their corresponding workflow files in `lib/github-api.ts`:

```typescript
const PROJECT_MAPPINGS = {
  "image-resizer": {
    workflowFile: "project-06-deploy.yml",
    displayName: "Smart Image Resizer",
  },
  "2048-game-cicd": {
    workflowFile: "project-13-deploy.yml",
    displayName: "2048 Game CI/CD",
  },
  // ... more projects
};
```

## Status Flow

1. **Idle**: No recent deployments
2. **Queued**: Workflow triggered, waiting to start
3. **In Progress**: Deployment actively running
4. **Completed**: Successful deployment
5. **Failed**: Deployment encountered errors
6. **Cancelled**: Deployment was cancelled

## Navigation

Access the deployment dashboard via:
- **Main Navigation**: "Deployments" link in navbar
- **Direct URL**: `/deployments`
- **Project Cards**: Individual deployment controls

## Security Considerations

- GitHub token is client-side (use with caution in production)
- Consider implementing server-side API routes for production
- Implement proper authentication and authorization
- Use environment-specific tokens

## Monitoring & Debugging

- Check browser console for API errors
- Verify GitHub token permissions
- Ensure workflow files exist and are properly configured
- Monitor GitHub Actions tab for workflow execution details

## Future Enhancements

- Server-side API routes for enhanced security
- Webhook integration for real-time updates
- Deployment history and logs
- Cost tracking and optimization alerts
- Multi-environment support (dev/staging/prod)