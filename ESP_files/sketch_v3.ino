#include <math.h> 
#include <SPIFFS.h>    // Or #include <LittleFS.h> for LittleFS

const int soilPin = 13;     // Soil moisture sensor
const int dryADC    = 4095;   // raw ADC when probe is in air
const int wetADC    = 530;   // raw ADC when probe is in water

const int ldrPin      = 34;   // Light sensor LDR
const int ntcPin      = 35;   // Temperature sensor (termistor) NTC

#define Rf 4700  // Fixed resistance in ohms (4.7kΩ)
#define Vcc 3.3  // Reference voltage (3.3V)

// Function to calculate the NTC resistance using the ADC value
float calculateNTCResistance(int rawADC) {
  // Convert the ADC value to voltage
  float voltage = (rawADC / 4095.0) * Vcc;
  
  // Calculate the NTC resistance using the voltage divider rule
  float RNTC = Rf * ((Vcc / voltage) - 1);
  
  return RNTC;
}

// Function to convert the NTC resistance to temperature (°C)
float calculateTemperature(float RNTC) {
  // Typical values for a 10kΩ NTC at 25°C
  float R0 = 10000.0;  // Resistance at 25°C (10kΩ)
  float B = 3950.0;    // B constant for the NTC
  
  // Simplified Steinhart-Hart equation
  float temperatureK = 1.0 / (1.0 / 298.15 + (1.0 / B) * log(RNTC / R0));  // Temperature in K
  float temperatureC = temperatureK - 273.15;  // Convert to °C
  
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
