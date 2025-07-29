import json
import os
import requests
import logging
from typing import Dict, Any


class GitHubActionsService:
    def __init__(self):
        self.token = os.environ.get("GITHUB_TOKEN")
        self.username = os.environ.get("GITHUB_USERNAME")
        self.repo = "aws-portfolio"
        self.logger = logging.getLogger(__name__)

    @property
    def base_url(self):
        return f"https://api.github.com/repos/{self.username}/{self.repo}"

    @property
    def headers(self):
        return {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json",
            "Content-Type": "application/json",
        }

    def _check_config(self):
        missing = []
        if not self.token:
            missing.append("GITHUB_TOKEN")
        if not self.username:
            missing.append("GITHUB_USERNAME")
        if missing:
            self.logger.error(f"Missing environment variables: {', '.join(missing)}")
            raise ValueError(f"Missing environment variables: {', '.join(missing)}")

    def get_workflow_status(self, project: str) -> str:
        try:
            self._check_config()
            url = f"{self.base_url}/actions/runs"
            params = {"per_page": 1, "branch": "main"}

            response = requests.get(url, headers=self.headers, params=params)
            data = response.json()

            if not data.get("workflow_runs"):
                return "NO_RUNS"

            latest_run = data["workflow_runs"][0]
            if project.lower() in latest_run["name"].lower():
                return latest_run["status"].upper()

            return "NOT_FOUND"
        except Exception:
            return "NOT_CONFIGURED"
    


    def trigger_deploy_workflow(self, project: str) -> dict:
        try:
            self._check_config()
            url = f"{self.base_url}/actions/workflows/{project}.yaml/dispatches"
            payload = json.dumps({"ref": "main"})

            response = requests.post(url, data=payload, headers=self.headers)
            response.raise_for_status()
            
            return {"status": "success", "message": "Workflow triggered"}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def trigger_destroy_workflow(self, project: str) -> dict:
        try:
            self._check_config()
            url = f"{self.base_url}/actions/workflows/{project}.yaml/dispatches"
            payload = json.dumps({"ref": "main", "inputs": {"action": "destroy"}})

            response = requests.post(url, data=payload, headers=self.headers)
            response.raise_for_status()
            
            return {"status": "success", "message": "Workflow triggered"}
        except Exception as e:
            return {"status": "error", "error": str(e)}
