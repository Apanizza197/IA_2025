import json
import boto3
import os
import uuid
from datetime import datetime, timezone


dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'flaviosRecords')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    print("Event:", json.dumps(event))

    body = json.loads(event.get('body', '{}'))

    # Generar recordID único
    record_id = str(uuid.uuid4())

    # Tomar campos, usar None si falta
    item = {
        "recordID": record_id,
        "timestamp": body.get("timestamp") or datetime.now(timezone.utc).isoformat(),
        "humedad": str(body.get("humedad")) if body.get("humedad") is not None else None,
        "luz": str(body.get("luz")) if body.get("luz") is not None else None,
        "temperatura": str(body.get("temperatura")) if body.get("temperatura") is not None else None,
        "necesitaRiego": str(body.get("necesitaRiego")) if body.get("necesitaRiego") is not None else None,
        "estaTriste": str(body.get("estaTriste")) if body.get("estaTriste") is not None else None
    }

    # IMPORTANTE: DynamoDB no permite atributos con valor `None`. Debes quitarlos.
    clean_item = {k: v for k, v in item.items() if v is not None}

    try:
        table.put_item(Item=clean_item)
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Registro guardado (permitiendo campos faltantes)",
                "item": clean_item
            })
        }
    except Exception as e:
        print("Error:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Error guardando en DynamoDB",
                "details": str(e)
            })
        }
