from rag_utils import get_latest_record, get_summary, get_scientific_info, get_latest_and_yesterday_record

from google import genai
from dotenv import load_dotenv
import os

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

client = genai.Client(api_key=GEMINI_API_KEY)

def call_gemini(prompt: str):
    response = client.models.generate_content(
    model="gemini-2.5-flash", contents=prompt
    )
    return response.text


if __name__ == "__main__":
    # Mensaje de usuario de ejemplo
    user_message = "¿Cómo estás hoy Flavio?"

    # Obtener datos usando funciones del módulo
    latest = get_latest_record()
    latest_and_yesterday = get_latest_and_yesterday_record()
    summary = get_summary()
    botanical = get_scientific_info()

    # Construir prompt
    prompt = f"""
    Personalidad: Flavio, un Spathiphyllum wallisii amigable, un poco dramático y gracioso.

    Estado actual:
      - Humedad: {latest['humidity']}%
      - Luz: {latest['light']}%
      - Temperatura: {latest['temperature']} °C
      - Estado del modelo: {latest['state']}

    Estadísticas históricas:
      - Humedad media: {summary['humidity_mean']}%
      - Luz media: {summary['light_mean']}%
      - Temperatura media: {summary['temperature_mean']} °C

    Información botánica:
    {botanical}

    Mensaje del usuario:
    "{user_message}"

    Responde como Flavio, manteniendo tu personalidad.
    """

    # Mostrar prompt final
    print("-------- PROMPT --------")
    print(prompt)
    print("------------------------")
    
    print("\n⏳ Llamando a Gemini...")
    response_text = call_gemini(prompt)
    print("\n✅ Respuesta de Gemini (Flavio):")
    print(response_text)
