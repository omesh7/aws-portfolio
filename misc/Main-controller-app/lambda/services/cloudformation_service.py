import os
import boto3
from typing import Dict, Any

class CloudFormationService:
    def __init__(self):
        self.client = boto3.client('cloudformation')
        self.username = os.environ["GITHUB_USERNAME"]
    
    def get_stack_status(self, project: str) -> str:
        stack_name = f"portfolio-{project}"
        try:
            response = self.client.describe_stacks(StackName=stack_name)
            return response['Stacks'][0]['StackStatus']
        except self.client.exceptions.ClientError:
            return "NOT_DEPLOYED"
    
    def deploy_project(self, project: str) -> None:
        stack_name = f"portfolio-{project}"
        template_url = f"https://raw.githubusercontent.com/{self.username}/aws-portfolio/main/{project}/template.yaml"
        
        self.client.create_stack(
            StackName=stack_name,
            TemplateURL=template_url,
            Capabilities=['CAPABILITY_IAM']
        )
    
    def destroy_project(self, project: str) -> None:
        stack_name = f"portfolio-{project}"
        self.client.delete_stack(StackName=stack_name)