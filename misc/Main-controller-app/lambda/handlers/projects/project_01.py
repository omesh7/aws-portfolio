import logging
from typing import Dict, Any
from services.terraform_service import TerraformService
from services.github_actions_service import GitHubActionsService
from utils.response import success_response, error_response
from .utils import Tf_variables

logger = logging.getLogger(__name__)


def start_project_01() -> Dict[str, Any]:
    """Static Website S3 - Terraform only deployment"""
    logger.info("Starting Project 1: Static Website S3 infrastructure")

    try:
        terraform_service = TerraformService()
        tf_variabless = Tf_variables()

        logger.debug(f"Using workspace ID: {tf_variabless.tf_workspace_id_1}")

        # Trigger Terraform apply only
        logger.info("Triggering Terraform apply for S3 infrastructure")
        terraform_service.trigger_apply(
            workspace_id=tf_variabless.tf_workspace_id_1, project=1
        )

        # Generate webhook URL for Terraform to call when complete
        # webhook_token = "tf-p1-x9k2m8n4q7w5e3r6t8y1u2i5o9p0a7s4d6f8g1h3j5k7l9"
        # webhook_url = f"https://cy7lmcwjkehkjmwfwzs3ukflce0rbuqb.lambda-url.ap-south-1.on.aws/webhook/{webhook_token}"

        logger.info("Project 1 infrastructure deployment triggered")
        return success_response(
            {
                "message": "Project 1: Infrastructure deployment started",
                "terraform_workspace_id": tf_variabless.tf_workspace_id_1,
                # "webhook_url": webhook_url,
                "comment": "Terraform will call webhook when infrastructure is ready",
            }
        )
    except Exception as e:
        logger.error(f"Failed to start Project 1: {str(e)}", exc_info=True)
        return error_response(
            f"Project 1 deployment failed: {str(e)}",
            500,
            debug_info={"project": "static-website-s3", "error_type": type(e).__name__},
        )


def webhook_project_01_deploy(webhook_token: str) -> Dict[str, Any]:
    """Webhook endpoint for Terraform to trigger GitHub Actions deployment"""
    logger.info(f"Webhook called for Project 1 deployment")

    # Validate webhook token
    expected_token = "tf-p1-x9k2m8n4q7w5e3r6t8y1u2i5o9p0a7s4d6f8g1h3j5k7l9"
    if webhook_token != expected_token:
        logger.warning(f"Invalid webhook token received: {webhook_token[:10]}...")
        return error_response("Invalid webhook token", 403)

    try:
        actions_service = GitHubActionsService()

        # Trigger GitHub Actions deployment
        logger.info("Infrastructure ready - triggering GitHub Actions deployment")
        workflow_run = actions_service.trigger_deploy_workflow(
            "01-static-website-deploy"
        )

        logger.info("Project 1 website deployment triggered successfully")
        return success_response(
            {
                "message": "Project 1: Website deployment triggered",
                "github_workflow_run_id": workflow_run.get("id"),
                "comment": "GitHub Actions deployment started",
            }
        )
    except Exception as e:
        logger.error(f"Failed to trigger Project 1 deployment: {str(e)}", exc_info=True)
        return error_response(
            f"Webhook deployment failed: {str(e)}",
            500,
            debug_info={"error_type": type(e).__name__},
        )
