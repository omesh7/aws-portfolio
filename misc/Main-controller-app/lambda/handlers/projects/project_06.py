from typing import Dict, Any
from services.terraform_service import TerraformService
from services.github_actions_service import GitHubActionsService
from utils.response import success_response, error_response

def start_project_06() -> Dict[str, Any]:
    """Smart Resize Images - Full stack with Terraform + Next.js"""
    try:
        terraform_service = TerraformService()
        actions_service = GitHubActionsService()
        
        # Create infrastructure (S3, Lambda, API Gateway)
        terraform_service.trigger_apply("06-smart-resize-images")
        
        # Deploy Next.js site and Lambda
        actions_service.trigger_deploy_workflow("06-smart-resize-images")
        
        return success_response({
            "message": "Started Project 6: Smart Resize Images",
            "comment": "Full-stack image resizing app with Next.js frontend, Lambda backend, and S3 storage"
        })
    except Exception as e:
        return error_response(str(e), 500)