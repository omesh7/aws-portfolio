from typing import Dict, Any
from services.github_actions_service import GitHubActionsService
from utils.response import success_response, error_response

def start_project_04() -> Dict[str, Any]:
    """Text-to-Speech Polly - Lambda deployment"""
    try:
        actions_service = GitHubActionsService()
        
        # Deploy Polly Lambda
        actions_service.trigger_deploy_workflow("04-text-to-speech-polly")
        
        return success_response({
            "message": "Started Project 4: Text-to-Speech Polly",
            "comment": "Node.js Lambda function using AWS Polly for text-to-speech conversion"
        })
    except Exception as e:
        return error_response(str(e), 500)