import pandas as pd

df = pd.read_csv("datos_planta2.csv")

def get_latest_record():
    """
    Devuelve el registro más reciente como dict.
    """
    latest = df.sort_values(by="timestamp").tail(1).iloc[0]
    return {
        "humidity": latest["humidity"],
        "light": latest["light"],
        "temperature": latest["temperature"],
        "state": latest["state"],
        "timestamp": latest["timestamp"],
    }
    
def get_latest_and_yesterday_record():
    """
    Devuelve el registro más reciente como dict.
    Incluye los campos de ayer por si se usan.
    """
    latest = df.sort_values(by="timestamp").tail(1).iloc[0]
    return {
        "humidity": latest["humidity"],
        "light": latest["light"],
        "temperature": latest["temperature"],
        "state": latest["state"],
        "timestamp": latest["timestamp"],
        "humidity_yesterday": latest["humidity_yesterday"],
        "light_yesterday": latest["light_yesterday"],
        "temperature_yesterday": latest["temperature_yesterday"],
    }


def get_summary():
    """
    Estadísticas simples del histórico.
    """
    summary = {
        "humidity_mean": round(df["humidity"].mean(), 2),
        "light_mean": round(df["light"].mean(), 2),
        "temperature_mean": round(df["temperature"].mean(), 2),
        "num_records": len(df)
    }
    return summary

def get_scientific_info():
    """
    Devuelve el contenido del resumen científico.
    """
    with open("resumen_cuidados.txt", "r") as f:
        return f.read()
