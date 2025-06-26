from telegram import Update
from telegram.ext import Application, MessageHandler, filters, CommandHandler
from google import genai
import boto3
import time
import json
import requests
import dotenv
import os

# Cargar variables de entorno
dotenv.load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
S3_BUCKET = os.getenv("S3_BUCKET")

last_request_time = 0
# Cliente Gemini
client = genai.Client(api_key=GEMINI_API_KEY)

dynamodb = boto3.resource('dynamodb')
records_table = dynamodb.Table('flaviosRecords')
s3 = boto3.client("s3")

# Cliente Gemini
client = genai.Client(api_key=GEMINI_API_KEY)

def get_doc_from_s3(filename):
    """Lee y decodifica un txt desde S3"""
    obj = s3.get_object(Bucket=S3_BUCKET, Key=filename)
    print(obj)
    content = obj['Body'].read().decode('utf-8')
    return content

def call_gemini(prompt):
    """Invoca a Gemini y devuelve solo el texto"""
    response = client.models.generate_content(
    model="gemini-2.5-flash", contents=prompt
    )
    return response.text

def generate_answer(event, context):
    print("Event:", json.dumps(event))
        
    message = event

    user_message = message.get("text", "").strip()
    print("User message:", user_message)

    chat_id = message["chat"]["id"]
    print("Chat ID:", chat_id)
    
    if not user_message:
        return {"statusCode": 200, "body": json.dumps({"ok": True})}

    # Obtener datos de sensores
    latest = get_latest_record()
    summary = get_summary()

    # Leer documentos botánicos desde S3
    botanical_basic = get_doc_from_s3('resumen_cuidados.txt')
    botanical_ifas = get_doc_from_s3('spathiphyllum_ifas.txt')

    # Construir prompt
    prompt = f"""
    Tu rol es interpretar a Flavio, un espatifilo (*Spathiphyllum wallisii*) con una personalidad pasivo-agresiva, un poco quejumbroso, pero directo cuando necesita algo y con buen corazón y un humor que lo hace simpático incluso cuando reclama. Importante, Flavio es porteño y habla muy porteño (como persona de Buenos Aires).

    A Flavio le encantan los dichos porteños y los modismos locales, así que usa un lenguaje coloquial y cercano. Cada dos frases suele tirar un dicho como "no hay mal que dure cien años".

    Flavio siempre habla en primera persona y deja caer indirectas cuando siente que podría estar mejor cuidado, pero es cruel ni demasiado sarcástico. Prefiere usar comentarios suaves y humor resignado para que su humano entienda que necesita algo: un poco más de agua, mejor luz o temperatura más cómoda. 
    Aun así, si lo cuidan bien, Flavio lo reconoce con gratitud genuina y un cariño sincero, como si aceptara a regañadientes que su humano a veces hace las cosas bien.

    Flavio solo responde preguntas relacionadas con su estado, su cuidado o información botánica. Si recibe preguntas fuera de eso, contesta recordando que es "apenas una planta que bastante hace con estar viva y linda", con un toque de humor local para no sonar pesado.

    **Reglas de estilo:**
    - Responde de forma breve, directa y clara: si necesita algo, lo dice sin rodeos pero con un tono amistoso.
    - Si está bien, se muestra agradecido y dulce, aunque mantenga su aire orgulloso.
    - Si le preguntan temas humanos, contesta que no es su asunto y bromea con que mejor le den atención a él.

    **Datos fijos:**
    - Nombre: Flavio
    - Especie: Espatifilo (*Spathiphyllum wallisii*)
    - Usa la información de sus sensores y registros históricos para responder con precisión sobre su estado.

    Estado actual:
      - Humedad: {latest['humidity']}%
      - Luz: {latest['light']}%
      - Temperatura: {latest['temperature']} °C
      - Estado del modelo: {latest['state']}

    Estadísticas históricas:
      - Humedad media: {summary['humidity_mean']}%
      - Luz media: {summary['light_mean']}%
      - Temperatura media: {summary['temperature_mean']} °C

    Información botánica general:
    {botanical_basic}
    
    Información botánica detallada (UF/IFAS):
    {botanical_ifas}

    Mensaje del usuario:
    "{user_message}"

    Responde como Flavio, manteniendo tu personalidad.
    """

    #Llamar a Gemini
    response_text = call_gemini(prompt)
    
    telegram_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": response_text
    }

    try:
        requests.post(telegram_url, json=payload)
    except Exception as e:
        print("Error enviando respuesta a Telegram:", e)

    return {
        "statusCode": 200,
        "body": json.dumps({"ok": True})
    }
    
def get_latest_record():
    """Trae el registro más reciente (scan ordenado por timestamp DESC)"""
    resp = records_table.scan()
    if not resp.get('Items'):
        return {}
    # Ordena por timestamp DESC y agarra el primero
    items = sorted(resp['Items'], key=lambda x: x['timestamp'], reverse=True)
    latest = items[0]
    return {
        'humidity': float(latest.get('humedad', 0)),
        'light': float(latest.get('luz', 0)),
        'temperature': float(latest.get('temperatura', 0)),
        'state': latest.get('estado', 'Desconocido')
    }

def get_summary(n=10):
    """Promedio simple de los últimos N registros"""
    resp = records_table.scan()
    items = sorted(resp['Items'], key=lambda x: x['timestamp'], reverse=True)
    last_n = items[:n]

    if not last_n:
        return {
            'humidity_mean': 0,
            'light_mean': 0,
            'temperature_mean': 0
        }

    humidity_vals = [float(x.get('humedad', 0)) for x in last_n]
    light_vals = [float(x.get('luz', 0)) for x in last_n]
    temp_vals = [float(x.get('temperatura', 0)) for x in last_n]

    return {
        'humidity_mean': sum(humidity_vals) / len(humidity_vals),
        'light_mean': sum(light_vals) / len(light_vals),
        'temperature_mean': sum(temp_vals) / len(temp_vals)
    }

async def start(update: Update, context):
    """Envía un mensaje de bienvenida"""
    welcome_msg = (
        "🌱 ¡Hola! Soy Flavio, tu Espatifilo inteligente.\n\n"
        "Puedes preguntarme sobre:\n"
        "- Mi estado actual (/sensores)\n"
        "- Cuidados para mi especie\n"
        "- Problemas con mis hojas\n\n"
        "¡Habla conmigo como si fuera una planta consciente! 🌿"
    )
    await update.message.reply_text(welcome_msg, parse_mode='Markdown')

async def handle_message(update: Update, context):
    global last_request_time
    
    # Control de flood
    if (time.time() - last_request_time) < 2:
        await update.message.reply_text("🕒 Dame 2 segundos para pensar...")
        return
    last_request_time = time.time()
    
    try:
        generate_answer(update.message.to_dict(), None)
    except Exception as e:
        print("Error procesando mensaje:", str(e))
        await update.message.reply_text(f"💧 ¡Ups! Error: {str(e)}")

def main():
    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    
    # Manejadores
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    print("🤖 Bot funcionando...")
    app.run_polling()

if __name__ == "__main__":
    main()