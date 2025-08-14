from . import routes
from .utils import logger



def lambda_handler(event, context):
    # Log the raw incoming event
    logger.info("=== Incoming Event ===")
    logger.info(event)

    # Extract and normalize path
    path = (event.get("rawPath") or event.get("path") or "").strip().lower().rstrip("/")

    # Extract HTTP method for both REST API v1 and HTTP API v2 / Lambda URLs
    method = (
        event.get("httpMethod")  # REST API v1
        or event.get("requestContext", {})
        .get("http", {})
        .get("method")  # HTTP API v2 / Lambda URL
        or ""
    )
    method = method.strip().upper()

    logger.info(f"Normalized Path: {path}")
    logger.info(f"Normalized Method: {method}")

    # Call route handler
    response = routes.handle_route(path, method, event, context)

    # Log the final response
    logger.info("=== Lambda Response ===")
    logger.info(response)

    return response
