import json
from typing import Dict, Any
from handlers.project_handler import (
    list_repos,
    check_project_status,
    start_project,
    destroy_project,
)
from utils.response import error_response


def route_request(event: Dict[str, Any]) -> Dict[str, Any]:
    path = event.get("rawPath", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")

    if path in ["/repos", "/repo"] and method == "GET":
        return list_repos()

    elif path == "/status" and method == "GET":
        params = event.get("queryStringParameters") or {}
        project = params.get("project")
        return check_project_status(project)

    elif path == "/start" and method == "POST":
        body = json.loads(event.get("body", "{}"))
        project = body.get("project")
        return start_project(project)

    elif path == "/destroy" and method == "POST":
        body = json.loads(event.get("body", "{}"))
        project = body.get("project")
        return destroy_project(project)

    elif path == "/":
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Welcome to the AWS Portfolio Controller"}),
        }

    else:
        return error_response("Not found", 404)
