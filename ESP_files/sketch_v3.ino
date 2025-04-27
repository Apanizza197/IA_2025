#include <math.h> 
#include <SPIFFS.h>    // Or #include <LittleFS.h> for LittleFS

const int soilPin = 13;     // AO → ADC1 channel (GPIO13)
const int dryADC    = 4095;   // raw ADC when probe is in air
const int wetADC    = 530;   // raw ADC when probe is in water

const int ldrPin      = 34;   //light sensor LDR
const int ntcPin      = 35;   //temperature sensor (termistor) NTC

#define Rf 4700  // Resistencia fija en ohmios (4.7kΩ)
#define Vcc 3.3  // Voltaje de referencia (3.3V)

// Función para calcular la resistencia del NTC usando el valor del ADC
float calculateNTCResistance(int rawADC) {
  // Convertir el valor del ADC a voltaje
  float voltage = (rawADC / 4095.0) * Vcc;
  
  // Calcular la resistencia del NTC usando la ley del divisor de voltaje
  float RNTC = Rf * ((Vcc / voltage) - 1);
  
  return RNTC;
}

// Función para convertir la resistencia del NTC en temperatura (en °C)
float calculateTemperature(float RNTC) {
  // Valores típicos para un NTC de 10kΩ a 25°C
  float R0 = 10000.0;  // Resistencia a 25°C (10kΩ)
  float B = 3950.0;    // Constante B para el NTC
  
  // Ecuación de Steinhart-Hart simplificada
  float temperatureK = 1.0 / (1.0 / 298.15 + (1.0 / B) * log(RNTC / R0));  // Temperatura en K
  float temperatureC = temperatureK - 273.15;  // Convertir a °C
  
  return temperatureC;
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("Initializing filesystem...");
  
  // Try mounting; format if mount fails
  if (!SPIFFS.begin(true)) {               // true → format if failed
    Serial.println("SPIFFS Mount Failed");
    return;
  }
  Serial.println("SPIFFS Mounted Successfully");

  Serial.println("Sensor Reader Starting...");
}

void loop() {
  // --- Soil moisture ---
  int rawSoil = analogRead(soilPin);
  // Map raw [dryADC…wetADC] → [0…100]
  // Note: if dryADC < wetADC, swap them or adjust accordingly.
  int soilPct = map(rawSoil, dryADC, wetADC, 0, 100);
  soilPct = constrain(soilPct, 0, 100);

  // --- Light ---
  int rawLDR = analogRead(ldrPin);
  // Raw reading from 0 to 4095 (more light → less resistance → more voltage)
  int lightPct = map(rawLDR, 570, 4095, 0, 100);

  // --- Temperature ---
  int rawNTC = analogRead(ntcPin);
  // Less temperature, more resistance of the NTC → less voltage
  float RNTC = calculateNTCResistance(rawNTC);
  float temperature = calculateTemperature(RNTC);

  // --- Show results ---
  Serial.println("----- Lecturas -----");
  Serial.printf("Humedad suelo: Raw ADC = %4d   Moisture = %3d%%\n", rawSoil, soilPct);
  Serial.printf("Luz ambiente : Raw ADC = %4d   Luz estimada = %3d%%\n", rawLDR, lightPct);
  Serial.printf("Temperatura   :Raw NTC = %4d   Temperature = %.2f °C\n", rawNTC, temperature);
  Serial.println("--------------------\n");

  // --- Append to file ---
  File logFile = SPIFFS.open("/sensor_log.txt", FILE_APPEND);
  if (logFile) {
    String entry = String(millis()) + "," + 
          String(soilPct) + "," +
          String(lightPct) + "," +
          String(temperature, 2) + 
          String(rawSoil) + "," +
          String(rawLDR) + "," +
          String(rawNTC, 2) + "\n";
    logFile.print(entry);
    logFile.close();
  } else {
    Serial.println("Error opening log file");
  }

  delay(600000); // 10 minutes
  //delay(1000); // Uncomment for testing
}
