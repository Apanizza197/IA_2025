import pandas as pd

df = pd.read_csv("datos_planta2.csv")

def get_latest_record():
    latest = df.sort_values(by="timestamp").tail(1).iloc[0]
    return {
        "humidity": latest["humidity"],
        "light": latest["light"],
        "temperature": latest["temperature"],
        "state": latest["state"],
        "timestamp": latest["timestamp"],
    }
    
def get_latest_and_yesterday_record():
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
    summary = {
        "humidity_mean": round(df["humidity"].mean(), 2),
        "light_mean": round(df["light"].mean(), 2),
        "temperature_mean": round(df["temperature"].mean(), 2),
        "num_records": len(df)
    }
    return summary

def get_scientific_info():
    with open("docs/resumen_cuidados.txt", "r") as f:
        return f.read()
    
def get_ifas_info():
    with open("docs/spathiphyllum_ifas.txt", "r") as f:
        return f.read().strip()
