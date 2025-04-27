#include <SPIFFS.h>    // Include SPIFFS library
#include <FS.h>

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("Initializing SPIFFS...");

  // Mount SPIFFS, format if mounting fails
  if (!SPIFFS.begin(true)) {
    Serial.println("SPIFFS Mount Failed");
    return;
  }
  Serial.println("SPIFFS Mounted");
}

void loop() {
  // Open the log file for reading
  File logFile = SPIFFS.open("/sensor_log.txt", FILE_READ);
  if (!logFile) {
    Serial.println("Failed to open log file for reading");
    delay(5000);
    return;
  }

  Serial.println("---- Sensor Log ----");
  // Read and print each line until EOF
  while (logFile.available()) {
    String line = logFile.readStringUntil('\n');
    Serial.println(line);
  }
  Serial.println("--------------------\n");

  logFile.close();  // Close file when done

  delay(10000);     // Wait before next print
}