from typing import Dict, Any
from services.github_actions_service import GitHubActionsService
from utils.response import success_response, error_response

def start_project_02() -> Dict[str, Any]:
    """Mass Email Lambda - Direct Lambda deployment"""
    try:
        actions_service = GitHubActionsService()
        
        # Deploy Lambda function directly
        actions_service.trigger_deploy_workflow("02-mass-email-lambda")
        
        return success_response({
            "message": "Started Project 2: Mass Email Lambda",
            "comment": "TypeScript Lambda function for mass email sending via SES"
        })
    except Exception as e:
        return error_response(str(e), 500)