import json
import os
import time
import uuid
import boto3
from decimal import Decimal

dynamo = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    try:
        body = event.get("body", "{}")
        payload = json.loads(body) if isinstance(body, str) else body

        item = {
            "deviceId": str(payload.get("deviceId", "unknown")),
            "ts": int(time.time() * 1000),
            "id": uuid.uuid4().hex,
            "temp": Decimal(str(payload.get("temp", 0))),
            "hum": Decimal(str(payload.get("hum", 0))),
            "raw": json.dumps(payload)
        }

        dynamo.put_item(Item=item)

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "status": "ok",
                "saved": {
                    "deviceId": item["deviceId"],
                    "ts": item["ts"]
                }
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "status": "error",
                "detail": str(e)
            })
        }
