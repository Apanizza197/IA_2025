import json
import boto3

dynamodb = boto3.resource('dynamodb')
records_table = dynamodb.Table('flaviosRecords')

def get_latest_record():
    resp = records_table.scan()
    items = sorted(resp.get('Items', []), key=lambda x: x['timestamp'], reverse=True)
    latest = items[0] if items else {}
    return {
        'humidity': float(latest.get('humedad', 0)),
        'light': float(latest.get('luz', 0)),
        'temperature': float(latest.get('temperatura', 0)),
        'state': latest.get('estado', 'Desconocido')
    }

def handler(event, context):
    latest = get_latest_record()

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "latest": latest
        })
    }
