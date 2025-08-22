# Grafana Monitoring Setup for 2048 Game

## Overview
This setup adds Grafana monitoring to the 2048 game project with efficient CloudWatch streaming for real-time metrics visualization.

## Architecture
```
CloudWatch Metrics → Grafana → Dashboard Visualization
├── ECS Container Insights
├── Application Load Balancer Metrics
├── Custom Application Metrics
└── Log Aggregation
```

## Features
- **Real-time Monitoring**: Live metrics from CloudWatch
- **Custom Dashboards**: Pre-configured 2048 game dashboard
- **Efficient Streaming**: Optimized CloudWatch data source
- **Containerized**: Runs on ECS Fargate
- **Auto-scaling**: Scales with application load

## Access Information
- **URL**: Available after deployment via `terraform output grafana_url`
- **Username**: admin
- **Password**: admin123

## Metrics Monitored
1. **ALB Metrics**:
   - Request count
   - Response time
   - HTTP status codes
   - Target health

2. **ECS Metrics**:
   - CPU utilization
   - Memory utilization
   - Task count
   - Service health

3. **Application Logs**:
   - Real-time log streaming
   - Error tracking
   - Performance insights

## Deployment
The Grafana setup is automatically deployed with the main infrastructure:

```bash
cd infrastructure/
terraform apply
```

## Configuration Files
- `datasources.yml`: CloudWatch data source configuration
- `dashboard.json`: Pre-built monitoring dashboard
- `grafana.tf`: Infrastructure as Code for Grafana setup

## Cost Optimization
- Uses Fargate Spot for cost efficiency
- Minimal resource allocation (512 CPU, 1GB RAM)
- Efficient CloudWatch API usage
- Log retention policies applied

## Security
- IAM roles with least privilege access
- VPC security groups
- CloudWatch read-only permissions
- Secure credential management