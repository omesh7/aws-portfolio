import os
import requests
from typing import Dict, Any


class TerraformService:
    def __init__(self):
        self.api_token = os.environ.get("TFC_API_TOKEN")
        self.org_name = os.environ.get("TFC_ORG_NAME")
        self.base_url = "https://app.terraform.io/api/v2"

    @property
    def headers(self):
        return {
            "Authorization": f"Bearer {self.api_token}",
            "Content-Type": "application/vnd.api+json",
        }

    def _check_config(self):
        if not self.api_token or not self.org_name:
            raise ValueError(
                "TFC_API_TOKEN and TFC_ORG_NAME environment variables required"
            )

    def get_workspace_status(self, workspace_name, project: str) -> str:
        try:
            self._check_config()

            url = f"{self.base_url}/organizations/{self.org_name}/workspaces/{workspace_name}"

            response = requests.get(url, headers=self.headers)
            if response.status_code == 404:
                return "NOT_DEPLOYED"

            data = response.json()
            current_run = data["data"]["relationships"]["current-run"]["data"]
            if not current_run:
                return "IDLE"

            run_id = current_run["id"]
            run_url = f"{self.base_url}/runs/{run_id}"
            run_response = requests.get(run_url, headers=self.headers)
            run_data = run_response.json()

            return run_data["data"]["attributes"]["status"].upper()
        except Exception:
            return "NOT_CONFIGURED"

    def trigger_apply(self, workspace_id, project: int) -> None:
        self._check_config()
        url = f"{self.base_url}/runs"

        payload = {
            "data": {
                "type": "runs",
                "attributes": {"message": f"Deploy {project} via API"},
                "relationships": {
                    "workspace": {"data": {"type": "workspaces", "id": workspace_id}}
                },
            }
        }

        response = requests.post(url, json=payload, headers=self.headers)
        response.raise_for_status()

    def get_run_status(self, workspace_id: str) -> str:
        """Get the current run status for a workspace"""
        self._check_config()
        
        # Get workspace to find current run
        workspace_url = f"{self.base_url}/workspaces/{workspace_id}"
        workspace_response = requests.get(workspace_url, headers=self.headers)
        workspace_response.raise_for_status()
        
        workspace_data = workspace_response.json()
        current_run = workspace_data["data"]["relationships"]["current-run"]["data"]
        
        if not current_run:
            return "idle"
        
        # Get run details
        run_id = current_run["id"]
        run_url = f"{self.base_url}/runs/{run_id}"
        run_response = requests.get(run_url, headers=self.headers)
        run_response.raise_for_status()
        
        run_data = run_response.json()
        return run_data["data"]["attributes"]["status"]

    def trigger_destroy(self, workspace_id, project: str) -> None:
        self._check_config()
        url = f"{self.base_url}/runs"

        payload = {
            "data": {
                "type": "runs",
                "attributes": {
                    "message": f"Destroy {project} via API",
                    "is-destroy": True,
                },
                "relationships": {
                    "workspace": {"data": {"type": "workspaces", "id": workspace_id}}
                },
            }
        }

        response = requests.post(url, json=payload, headers=self.headers)
        response.raise_for_status()
