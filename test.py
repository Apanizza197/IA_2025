import boto3
import dotenv
import os

# Cargar variables de entorno
dotenv.load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
S3_BUCKET = os.getenv("S3_BUCKET")


dynamodb = boto3.resource('dynamodb')
records_table = dynamodb.Table('flaviosRecords')
s3 = boto3.client("s3")



def get_doc_from_s3(filename):
    """Lee y decodifica un txt desde S3"""
    obj = s3.get_object(Bucket=S3_BUCKET, Key=filename)
    print(obj)
    content = obj['Body'].read().decode('utf-8')
    return content

print("S3_BUCKET:", S3_BUCKET)

get_doc_from_s3('resumen_cuidados.txt')