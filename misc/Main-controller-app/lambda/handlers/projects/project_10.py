from typing import Dict, Any
from services.terraform_service import TerraformService
from services.github_actions_service import GitHubActionsService
from utils.response import success_response, error_response

def start_project_10() -> Dict[str, Any]:
    """Kinesis ECR ML - Complex infrastructure with Docker"""
    try:
        terraform_service = TerraformService()
        actions_service = GitHubActionsService()
        
        # Create ECR repository first
        terraform_service.trigger_apply("10-kinesis-ecr-ml/state-file-infra")
        
        # Create main infrastructure (Kinesis, Lambda, DynamoDB)
        terraform_service.trigger_apply("10-kinesis-ecr-ml")
        
        # Deploy Docker container to ECR and Lambda
        actions_service.trigger_deploy_workflow("10-kinesis-ecr-ml")
        
        return success_response({
            "message": "Started Project 10: Kinesis ECR ML",
            "comment": "Complex ML pipeline with Kinesis streams, ECR Docker containers, and Lambda processing"
        })
    except Exception as e:
        return error_response(str(e), 500)