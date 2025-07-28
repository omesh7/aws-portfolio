from typing import Dict, Any
from services.github_service import GitHubService
from services.terraform_service import TerraformService
from services.github_actions_service import GitHubActionsService
from utils.response import success_response, error_response

# Project-specific handlers
from handlers.projects.project_01 import start_project_01
from handlers.projects.project_02 import start_project_02
from handlers.projects.project_03 import start_project_03
from handlers.projects.project_04 import start_project_04
from handlers.projects.project_06 import start_project_06
from handlers.projects.project_10 import start_project_10

# Main services
github_service = GitHubService()
terraform_service = TerraformService()
actions_service = GitHubActionsService()

# Project routing map
PROJECT_HANDLERS = {
    1: start_project_01,
    2: start_project_02,
    3: start_project_03,
    4: start_project_04,
    6: start_project_06,
    10: start_project_10
}

def list_repos() -> Dict[str, Any]:
    projects = github_service.get_project_folders()
    return success_response({"projects": projects})

def check_project_status(project: str) -> Dict[str, Any]:
    if not project:
        return error_response("Project parameter required")
    
    # Check both infrastructure and deployment status
    infrastructure_status = terraform_service.get_workspace_status(project)
    deployment_status = actions_service.get_workflow_status(project)
    
    return success_response({
        "project": project,
        "infrastructure": infrastructure_status,
        "deployment": deployment_status
    })

def start_project(project_id: str) -> Dict[str, Any]:
    if not project_id:
        return error_response("Project ID parameter required")
    
    try:
        # Convert project_id to integer
        project_num = int(project_id)
        
        # Check if project handler exists
        if project_num not in PROJECT_HANDLERS:
            return error_response(f"Project {project_num} not found or not implemented")
        
        # Route to specific project handler
        handler = PROJECT_HANDLERS[project_num]
        return handler()
        
    except ValueError:
        return error_response("Project ID must be a number")
    except Exception as e:
        return error_response(str(e), 500)

def destroy_project(project: str) -> Dict[str, Any]:
    if not project:
        return error_response("Project parameter required")
    
    try:
        # Step 1: Stop application deployment
        actions_service.trigger_destroy_workflow(project)
        
        # Step 2: Destroy infrastructure
        terraform_service.trigger_destroy(project)
        
        return success_response({"message": f"Started destroying {project}: deployment + infrastructure"})
    except Exception as e:
        return error_response(str(e), 500)