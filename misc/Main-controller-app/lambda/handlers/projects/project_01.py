import logging
from typing import Dict, Any
from services.terraform_service import TerraformService
from services.github_actions_service import GitHubActionsService
from utils.response import success_response, error_response
from .utils import Tf_variables

logger = logging.getLogger(__name__)


def start_project_01() -> Dict[str, Any]:
    """Static Website S3 - Terraform + GitHub Actions deployment"""
    logger.info("Starting Project 1: Static Website S3 deployment")
    
    try:
        terraform_service = TerraformService()
        actions_service = GitHubActionsService()
        tf_variabless = Tf_variables()
        
        logger.debug(f"Using workspace ID: {tf_variabless.tf_workspace_id_1}")

        # Trigger Terraform apply
        logger.info("Triggering Terraform apply for S3 infrastructure")
        terraform_service.trigger_apply(
            workspace_id=tf_variabless.tf_workspace_id_1, project=1
        )
        
        # Trigger GitHub Actions deployment
        logger.info("Triggering GitHub Actions deployment")
        workflow_run = actions_service.trigger_deploy_workflow("01-static-website-deploy")
        
        logger.info("Project 1 deployment triggered successfully")
        return success_response({
            "message": "Project 1: Static Website S3 deployment triggered",
            "terraform_workspace_id": tf_variabless.tf_workspace_id_1,
            "github_workflow_run_id": workflow_run.get("id"),
            "comment": "Both Terraform and GitHub Actions have been triggered"
        })
    except Exception as e:
        logger.error(f"Failed to start Project 1: {str(e)}", exc_info=True)
        return error_response(
            f"Project 1 deployment failed: {str(e)}", 
            500,
            debug_info={"project": "static-website-s3", "error_type": type(e).__name__}
        )
