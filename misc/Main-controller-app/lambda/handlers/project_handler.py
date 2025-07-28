from typing import Dict, Any
from services.github_service import GitHubService
from services.terraform_service import TerraformService
from services.github_actions_service import GitHubActionsService
from utils.response import success_response, error_response

github_service = GitHubService()
terraform_service = TerraformService()
actions_service = GitHubActionsService()

def list_repos() -> Dict[str, Any]:
    projects = github_service.get_project_folders()
    return success_response({"projects": projects})

def check_project_status(project: str) -> Dict[str, Any]:
    if not project:
        return error_response("Project parameter required")
    
    terraform_status = terraform_service.get_workspace_status(project)
    workflow_status = actions_service.get_workflow_status(project)
    
    return success_response({
        "project": project,
        "terraform_status": terraform_status,
        "workflow_status": workflow_status
    })

def start_project(project: str) -> Dict[str, Any]:
    if not project:
        return error_response("Project parameter required")
    
    try:
        actions_service.trigger_deploy_workflow(project)
        terraform_service.trigger_apply(project)
        return success_response({"message": f"Started deploying {project}"})
    except Exception as e:
        return error_response(str(e), 500)

def destroy_project(project: str) -> Dict[str, Any]:
    if not project:
        return error_response("Project parameter required")
    
    try:
        actions_service.trigger_destroy_workflow(project)
        terraform_service.trigger_destroy(project)
        return success_response({"message": f"Started destroying {project}"})
    except Exception as e:
        return error_response(str(e), 500)