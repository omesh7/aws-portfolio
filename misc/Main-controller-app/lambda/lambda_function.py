from typing import Dict, Any
from utils.router import route_request
from utils.response import error_response

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        return route_request(event)
    except Exception as e:
        return error_response(str(e), 500)
