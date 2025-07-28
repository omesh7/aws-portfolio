from typing import Dict, Any
from services.github_actions_service import GitHubActionsService
from utils.response import success_response, error_response

def start_project_03() -> Dict[str, Any]:
    """Custom Alexa Skill - Lambda deployment"""
    try:
        actions_service = GitHubActionsService()
        
        # Deploy Alexa skill Lambda
        actions_service.trigger_deploy_workflow("03-custom-alexa-skill")
        
        return success_response({
            "message": "Started Project 3: Custom Alexa Skill",
            "comment": "Node.js Lambda function for custom Alexa skill"
        })
    except Exception as e:
        return error_response(str(e), 500)