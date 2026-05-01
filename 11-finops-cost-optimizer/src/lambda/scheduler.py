"""
FinOps Cost Optimizer — EC2 Scheduler Lambda
Stops/starts EC2 instances based on 'AutoSchedule' tag.

Tag format:
  Key:   AutoSchedule
  Value: start=08:00;stop=20:00;tz=Asia/Kolkata;days=Mon-Fri

Supports:
  - Timezone-aware scheduling
  - Day-of-week filtering
  - SNS notification on every action
  - Dry-run mode via env var DRY_RUN=true
"""

import os
import json
import logging
from datetime import datetime
import boto3
import pytz

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")
DRY_RUN = os.environ.get("DRY_RUN", "false").lower() == "true"
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")

DAYS_MAP = {
    "Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3,
    "Fri": 4, "Sat": 5, "Sun": 6
}


def parse_schedule(tag_value: str) -> dict:
    """Parse 'start=08:00;stop=20:00;tz=Asia/Kolkata;days=Mon-Fri'"""
    config = {}
    for part in tag_value.split(";"):
        if "=" in part:
            key, val = part.strip().split("=", 1)
            config[key.strip()] = val.strip()
    return config


def is_within_active_days(config: dict, now: datetime) -> bool:
    days_raw = config.get("days", "Mon-Fri")
    if "-" in days_raw:
        start_day, end_day = days_raw.split("-")
        start_idx = DAYS_MAP.get(start_day, 0)
        end_idx = DAYS_MAP.get(end_day, 4)
        return start_idx <= now.weekday() <= end_idx
    else:
        allowed = [DAYS_MAP[d] for d in days_raw.split(",") if d in DAYS_MAP]
        return now.weekday() in allowed


def get_action(config: dict, now: datetime) -> str | None:
    """Return 'start', 'stop', or None (no action needed now)."""
    tz_name = config.get("tz", "UTC")
    try:
        tz = pytz.timezone(tz_name)
    except pytz.UnknownTimeZoneError:
        logger.warning(f"Unknown timezone '{tz_name}', defaulting to UTC")
        tz = pytz.utc

    local_now = now.astimezone(tz)

    if not is_within_active_days(config, local_now):
        return "stop"  # Outside business days → stop

    current_time = local_now.strftime("%H:%M")
    start_time = config.get("start", "08:00")
    stop_time = config.get("stop", "20:00")

    if current_time == start_time:
        return "start"
    elif current_time == stop_time:
        return "stop"
    return None


def get_tagged_instances() -> list[dict]:
    """Fetch all EC2 instances with AutoSchedule tag."""
    paginator = ec2.get_paginator("describe_instances")
    instances = []

    for page in paginator.paginate(
        Filters=[{"Name": "tag-key", "Values": ["AutoSchedule"]}]
    ):
        for reservation in page["Reservations"]:
            for inst in reservation["Instances"]:
                state = inst["State"]["Name"]
                if state in ("terminated", "terminating"):
                    continue
                tags = {t["Key"]: t["Value"] for t in inst.get("Tags", [])}
                instances.append({
                    "id": inst["InstanceId"],
                    "state": state,
                    "schedule": tags.get("AutoSchedule", ""),
                    "name": tags.get("Name", inst["InstanceId"]),
                })

    return instances


def notify(subject: str, message: dict):
    """Publish action summary to SNS."""
    if not SNS_TOPIC_ARN:
        logger.info("No SNS_TOPIC_ARN set, skipping notification")
        return
    try:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=json.dumps(message, indent=2),
        )
    except Exception as e:
        logger.error(f"SNS publish failed: {e}")


def lambda_handler(event, context):
    now = datetime.now(tz=pytz.utc)
    logger.info(f"Scheduler triggered at {now.isoformat()} | DRY_RUN={DRY_RUN}")

    instances = get_tagged_instances()
    logger.info(f"Found {len(instances)} tagged instances")

    actions_taken = []
    skipped = []

    for inst in instances:
        if not inst["schedule"]:
            skipped.append(inst["id"])
            continue

        try:
            config = parse_schedule(inst["schedule"])
        except Exception as e:
            logger.warning(f"Failed to parse schedule for {inst['id']}: {e}")
            skipped.append(inst["id"])
            continue

        action = get_action(config, now)

        if action is None:
            logger.info(f"No action required for {inst['name']} ({inst['id']}) at this time")
            continue

        current_state = inst["state"]

        # Guard: don't start an already-running instance, etc.
        if action == "start" and current_state == "running":
            logger.info(f"  {inst['name']} already running, skipping start")
            continue
        if action == "stop" and current_state == "stopped":
            logger.info(f"  {inst['name']} already stopped, skipping stop")
            continue

        if DRY_RUN:
            logger.info(f"  [DRY RUN] Would {action} {inst['name']} ({inst['id']})")
            actions_taken.append({"instance": inst["name"], "id": inst["id"], "action": f"DRY_RUN:{action}"})
            continue

        try:
            if action == "start":
                ec2.start_instances(InstanceIds=[inst["id"]])
                logger.info(f"  ✅ Started {inst['name']} ({inst['id']})")
            elif action == "stop":
                ec2.stop_instances(InstanceIds=[inst["id"]])
                logger.info(f"  ✅ Stopped {inst['name']} ({inst['id']})")

            actions_taken.append({
                "instance": inst["name"],
                "id": inst["id"],
                "action": action,
                "previous_state": current_state,
            })

        except Exception as e:
            logger.error(f"  ❌ Failed to {action} {inst['id']}: {e}")

    summary = {
        "timestamp": now.isoformat(),
        "environment": ENVIRONMENT,
        "dry_run": DRY_RUN,
        "actions_taken": actions_taken,
        "skipped": skipped,
        "total_instances_checked": len(instances),
    }

    logger.info(f"Summary: {json.dumps(summary, indent=2)}")

    if actions_taken:
        notify(
            subject=f"[FinOps] EC2 Scheduler — {len(actions_taken)} action(s) taken",
            message=summary,
        )

    return summary
