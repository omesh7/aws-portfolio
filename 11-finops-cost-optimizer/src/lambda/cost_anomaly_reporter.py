"""
FinOps Cost Optimizer — Cost Anomaly Reporter Lambda
Triggered by AWS Cost Anomaly Detection SNS alerts.
Enriches the alert with context and re-publishes to a human-readable SNS topic.
"""

import os
import json
import logging
import boto3
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns = boto3.client("sns")
ce = boto3.client("ce")

ALERT_SNS_TOPIC_ARN = os.environ.get("ALERT_SNS_TOPIC_ARN", "")
COST_THRESHOLD_USD = float(os.environ.get("COST_THRESHOLD_USD", "10.0"))


def get_last_30_day_costs() -> dict:
    """Fetch service-level costs for context."""
    today = datetime.utcnow().strftime("%Y-%m-%d")
    # Approximate 30-day window
    from datetime import timedelta
    start = (datetime.utcnow() - timedelta(days=30)).strftime("%Y-%m-%d")

    try:
        response = ce.get_cost_and_usage(
            TimePeriod={"Start": start, "End": today},
            Granularity="MONTHLY",
            Metrics=["UnblendedCost"],
            GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}],
        )

        costs = {}
        for result in response.get("ResultsByTime", []):
            for group in result.get("Groups", []):
                service = group["Keys"][0]
                amount = float(group["Metrics"]["UnblendedCost"]["Amount"])
                if amount > 0.01:
                    costs[service] = round(amount, 2)

        return dict(sorted(costs.items(), key=lambda x: x[1], reverse=True)[:10])

    except Exception as e:
        logger.error(f"Failed to fetch cost breakdown: {e}")
        return {}


def format_alert(anomaly: dict, top_costs: dict) -> str:
    impact = anomaly.get("impact", {})
    total_impact = impact.get("totalImpact", 0)
    expected = impact.get("expectedSpend", 0)
    actual = impact.get("actualSpend", 0)

    lines = [
        "🚨 AWS Cost Anomaly Detected",
        "=" * 40,
        f"Anomaly ID:      {anomaly.get('anomalyId', 'N/A')}",
        f"Time Range:      {anomaly.get('anomalyStartDate', 'N/A')} → {anomaly.get('anomalyEndDate', 'ongoing')}",
        f"Expected Spend:  ${expected:.2f}",
        f"Actual Spend:    ${actual:.2f}",
        f"Total Impact:    ${total_impact:.2f} over expected",
        "",
        "Root Cause:",
    ]

    for rc in anomaly.get("rootCauses", []):
        lines.append(f"  • Service: {rc.get('service', 'Unknown')}")
        lines.append(f"    Region:  {rc.get('region', 'N/A')}")
        lines.append(f"    Usage:   {rc.get('usageType', 'N/A')}")

    if top_costs:
        lines.append("")
        lines.append("Top 10 Services (Last 30 Days):")
        for svc, cost in top_costs.items():
            lines.append(f"  ${cost:>8.2f}  {svc}")

    lines.append("")
    lines.append("Action: Review AWS Cost Explorer immediately.")
    lines.append("https://console.aws.amazon.com/cost-management/home#/anomaly-detection")

    return "\n".join(lines)


def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    for record in event.get("Records", []):
        try:
            message = json.loads(record["Sns"]["Message"])
        except (KeyError, json.JSONDecodeError) as e:
            logger.error(f"Failed to parse SNS message: {e}")
            continue

        anomalies = message.get("anomalies", [])
        if not anomalies:
            logger.info("No anomalies in message, skipping")
            continue

        for anomaly in anomalies:
            impact = anomaly.get("impact", {}).get("totalImpact", 0)

            if impact < COST_THRESHOLD_USD:
                logger.info(f"Impact ${impact:.2f} below threshold ${COST_THRESHOLD_USD:.2f}, skipping")
                continue

            top_costs = get_last_30_day_costs()
            alert_body = format_alert(anomaly, top_costs)

            logger.info(f"Publishing cost anomaly alert: ${impact:.2f} impact")

            if ALERT_SNS_TOPIC_ARN:
                sns.publish(
                    TopicArn=ALERT_SNS_TOPIC_ARN,
                    Subject=f"[FinOps Alert] AWS Cost Anomaly: ${impact:.2f} over expected",
                    Message=alert_body,
                )

    return {"statusCode": 200, "body": "Processed"}
