import os
from typing import List
from github import Github

class GitHubService:
    def __init__(self):
        self.username = os.environ.get("GITHUB_USERNAME")
        self.token = os.environ.get("GITHUB_TOKEN")
        self._client = None
        self._repo = None
    
    @property
    def client(self):
        if not self._client:
            if not self.token:
                raise ValueError("GITHUB_TOKEN environment variable required")
            self._client = Github(self.token)
        return self._client
    
    @property
    def repo(self):
        if not self._repo:
            if not self.username:
                raise ValueError("GITHUB_USERNAME environment variable required")
            self._repo = self.client.get_repo(f"{self.username}/aws-portfolio")
        return self._repo
    
    def get_project_folders(self) -> List[str]:
        try:
            contents = self.repo.get_contents("")
            return [item.path for item in contents if item.type == "dir"]
        except Exception:
            return []