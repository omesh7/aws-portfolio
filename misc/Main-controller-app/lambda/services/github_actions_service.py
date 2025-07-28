import os
import requests
from typing import Dict, Any

class GitHubActionsService:
    def __init__(self):
        self.token = os.environ.get("GITHUB_TOKEN")
        self.username = os.environ.get("GITHUB_USERNAME")
        self.repo = "aws-portfolio"
    
    @property
    def base_url(self):
        return f"https://api.github.com/repos/{self.username}/{self.repo}"
    
    @property
    def headers(self):
        return {
            "Authorization": f"token {self.token}",
            "Accept": "application/vnd.github.v3+json"
        }
    
    def _check_config(self):
        if not self.token or not self.username:
            raise ValueError("GITHUB_TOKEN and GITHUB_USERNAME environment variables required")
    
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
    
    def trigger_deploy_workflow(self, project: str) -> None:
        self._check_config()
        url = f"{self.base_url}/actions/workflows/deploy-{project}.yml/dispatches"
        
        payload = {
            "ref": "main",
            "inputs": {"action": "deploy"}
        }
        
        response = requests.post(url, json=payload, headers=self.headers)
        response.raise_for_status()
    
    def trigger_destroy_workflow(self, project: str) -> None:
        self._check_config()
        url = f"{self.base_url}/actions/workflows/deploy-{project}.yml/dispatches"
        
        payload = {
            "ref": "main",
            "inputs": {"action": "destroy"}
        }
        
        response = requests.post(url, json=payload, headers=self.headers)
        response.raise_for_status()