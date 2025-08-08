from typing import Any, Dict
from app.routes import handle_route
from utils import logger


@logger.inject_lambda_context(log_event=True)
def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    path = event.get("path", "")
    method = event.get("httpMethod", "")
    return handle_route(path, method, event)
