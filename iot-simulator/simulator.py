import os
import random
import time

import requests

FARM_DATA_URL = os.getenv("FARM_DATA_URL", "http://farm-data-service.farm-db-svc.svc.cluster.local:8000")
INTERVAL_SECONDS = int(os.getenv("INTERVAL_SECONDS", "60"))

sensor_state = {
    "temperature_c": round(random.uniform(19.0, 22.0), 1),
    "humidity_percent": round(random.uniform(68.0, 76.0), 1),
    "light_lux": round(random.uniform(5200.0, 6800.0), 0),
    "energy_kwh": round(random.uniform(8.0, 11.0), 2),
}


def clamp(value, minimum, maximum):
    return max(minimum, min(maximum, value))


def generate_telemetry():
    # Perubahan dibuat bertahap agar simulasi sensor lebih mendekati pembacaan real.
    sensor_state["temperature_c"] = round(clamp(sensor_state["temperature_c"] + random.uniform(-0.35, 0.35), 17.0, 25.0), 1)
    sensor_state["humidity_percent"] = round(clamp(sensor_state["humidity_percent"] + random.uniform(-1.2, 1.2), 60.0, 85.0), 1)
    sensor_state["light_lux"] = round(clamp(sensor_state["light_lux"] + random.uniform(-350.0, 350.0), 2500.0, 9500.0), 0)
    sensor_state["energy_kwh"] = round(clamp(sensor_state["energy_kwh"] + random.uniform(-0.45, 0.45), 5.0, 15.0), 2)

    return {
        "temperature_c": sensor_state["temperature_c"],
        "humidity_percent": sensor_state["humidity_percent"],
        "light_lux": sensor_state["light_lux"],
        "energy_kwh": sensor_state["energy_kwh"]
    }


def send_telemetry():
    data = generate_telemetry()
    try:
        response = requests.post(f"{FARM_DATA_URL}/telemetry", json=data, timeout=5)
        if response.status_code == 200:
            print(f"Sent: {data}")
        else:
            print(f"Failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    print(f"Starting IoT simulator, sending to {FARM_DATA_URL} every {INTERVAL_SECONDS}s")
    while True:
        send_telemetry()
        time.sleep(INTERVAL_SECONDS)
