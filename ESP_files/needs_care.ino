#include <math.h>
#include <SPIFFS.h>

const int soilPin = 13;      // Soil-moisture sensor  (ADC2)
const int dryADC  = 2600;    // Probe in air
const int wetADC  = 750;     // Probe in water

const int ldrPin  = 34;      // LDR (ADC1)
const int ntcPin  = 35;      // NTC (ADC1)
#define bluePin 4
#define redPin 5

#define Rf  4700.0f          // 4.7 kΩ
#define Vcc 3.3f

static constexpr size_t   CHUNK    = 512;
static constexpr uint16_t N_LINES  = 150;

// ─────────────────────────────────  ML coefficients  ──
const float MEAN[6]  = { 24.55f, 20.96f, 17.98f, 26.77f, 20.96f, 19.21f };
const float SCALE[6] = { 24.23f, 2.40f, 41.75f, 24.35f, 2.73f, 41.56f };
const float COEF[6]  = { -0.28f, 0.863f, -0.22f, -0.541f, 1.591f, -0.278f };
const float BIAS     =  -0.0696f;

// ─────────────────────────────────  Helpers  ──────────
int get_meaned_analog_reading(int pin){
    long sum = 0;
    for (int i = 0; i < 10; ++i) {
        sum += analogRead(pin);
        delay(10);
    }
    return sum / 10;
}

float calculateNTCResistance(int rawADC)
{
    float voltage = rawADC * Vcc / 4095.0f;
    return Rf * ((Vcc / voltage) - 1.0f);
}

float calculateTemperature(float RNTC)
{
    constexpr float R0 = 10000.0f;  // at 25 °C
    constexpr float B  = 3950.0f;
    float invT = 1.0f / 298.15f + logf(RNTC / R0) / B;
    return (1.0f / invT) - 273.15f;
}

bool needWater(float humidity, float temperature, float light, float pastHumidity, float pastTemp, float pastLight)
{
    float z = BIAS;
    const float x[6] = { humidity, temperature, light, pastHumidity, pastTemp, pastLight };
    for (int i = 0; i < 6; ++i)
        z += COEF[i] * ((x[i] - MEAN[i]) / SCALE[i]);
    float prob = 1.0f / (1.0f + expf(-z));
    return prob > 0.2f;
}

// ────────────────────────────────  Last-N-lines helper  ──
String nthLineFromEnd(File &f)
{
    size_t fsize = f.size();
    if (!fsize) return "";

    static char buf[CHUNK];
    int16_t linesLeft = N_LINES;
    size_t  pos       = fsize;
    String  line;

    while (pos && linesLeft) {
        size_t toRead = (pos >= CHUNK) ? CHUNK : pos;
        pos -= toRead;
        f.seek(pos);
        f.read(reinterpret_cast<uint8_t*>(buf), toRead);

        for (int i = toRead - 1; i >= 0; --i) {
            char c = buf[i];
            if (c == '\n') {
                if (--linesLeft == 0)
                    line.reserve(fsize - (pos + i + 1));
                if (linesLeft < 0) break;
            }
            if (linesLeft <= 0) line = c + line;
        }
    }
    Serial.println(line);
    return line;
}

// ───────────────────────────────  CSV writer  ───────────
void writeFile(int soilPct, int lightPct, float temperature, int rawSoil, int rawLDR, int rawNTC){
  File logFile = SPIFFS.open("/sensor_log.txt", FILE_APPEND);
    if (logFile) {
      String entry = String(millis()) + "," +
            String(soilPct) + "," +
            String(lightPct) + "," +
            String(temperature, 2) + "," +
            String(rawSoil) + "," +
            String(rawLDR) + "," +
            String(rawNTC, 2) + "\n";
      logFile.print(entry);
      logFile.close();
    } else {
      Serial.println("Error opening log file");
    }
  }

// ───────────────────────────────  CSV parser  ───────────
struct SensorValues {
    int  humidity;
    int  light;
    int  temp;
    bool valid;
};

struct SensorValues valuesFromLine(const String &line)
{
    int p1 = line.indexOf(',');
    int p2 = line.indexOf(',', p1 + 1);
    int p3 = line.indexOf(',', p2 + 1);
    if (p1 < 0 || p2 < 0 || p3 < 0) return {0, 0, 0, false};

    return { line.substring(p1 + 1, p2).toInt(),
             line.substring(p2 + 1, p3).toInt(),
             line.substring(p3 + 1).toInt(),
             true };
}

struct SensorValues getPastValues()
{
    File f = SPIFFS.open("/sensor_log.txt", FILE_READ);
    if (!f) {
        Serial.println("Failed to open /sensor_log.txt");
        return {0, 0, 0, false};
    }
    SensorValues v = valuesFromLine(nthLineFromEnd(f));
    Serial.println("Got values successfully");
    f.close();
    return v;
}

// ───────────────────────────────  Pretty print  ─────────
void printSensorData(int rawSoil, int soilPct,
                     int rawLDR,  int lightPct,
                     int rawNTC,  float tempC)
{
    Serial.println(F("----- Lecturas -----"));
    Serial.printf("Humedad suelo : %4d ADC  -> %3d %%\n", rawSoil, soilPct);
    Serial.printf("Luz ambiente  : %4d ADC  -> %3d %%\n", rawLDR,  lightPct);
    Serial.printf("Temperatura   : %4d ADC  -> %5.2f °C\n", rawNTC, tempC);
    Serial.println(F("--------------------\n"));
}

// ───────────────────────────────  Switch light ─────────
void lightSwitch(bool on, int pin){
    if (on) digitalWrite(pin, LOW);
    else digitalWrite(pin, HIGH);   
}

// ───────────────────────────────  Arduino setup  ────────
void setup()
{
    Serial.begin(115200);
    delay(200);

    if (!SPIFFS.begin(true)) {
        Serial.println("SPIFFS Mount Failed");
        while (true) delay(1000);
    }
    Serial.println("SPIFFS mounted.");

    pinMode(redPin,OUTPUT);
    pinMode(bluePin,OUTPUT);
    lightSwitch(false, bluePin);
    lightSwitch(false, redPin);
}

// ───────────────────────────────  Main loop  ────────────
void loop()
{
    delay(1000);
    // Soil-moisture %
    int rawSoil = get_meaned_analog_reading(soilPin);
    int soilPct = constrain(map(rawSoil, dryADC, wetADC, 0, 100), 0, 100);

    // Light %
    int rawLDR  = get_meaned_analog_reading(ldrPin);
    int lightPct = constrain(map(rawLDR, 570, 4095, 0, 100), 0, 100);

    // Temperature °C
    int   rawNTC = get_meaned_analog_reading(ntcPin);
    float tempC  = calculateTemperature(calculateNTCResistance(rawNTC));

    printSensorData(rawSoil, soilPct, rawLDR, lightPct, rawNTC, tempC);
    Serial.println("Updating file with last records");
    writeFile(soilPct, lightPct, tempC, rawSoil, rawLDR, rawNTC);

    Serial.println("Retrieving historical values");
    // Fetch historic values
    struct SensorValues past = getPastValues();
    if (past.valid) {
        Serial.printf("Hace ~150 lecturas: H=%d%% L=%d%% T=%d °C\n",
                      past.humidity, past.light, past.temp);
    }
    else{
      Serial.println("Failed to retrieve past values");
    }

    Serial.println("Checkeando el estado de Flavio");
    bool isSad= needWater(soilPct, tempC, lightPct, past.humidity, past.light, past.temp);
    Serial.printf("¿Esta Flavio triste? %s\n\n", isSad ? "SÍ" : "no");
    lightSwitch(isSad, redPin);

    bool mustWater = isSad && (soilPct < 65);
    Serial.printf("¿Regar?  %s\n\n", mustWater ? "SÍ" : "no");
    lightSwitch(mustWater, bluePin);

    delay(600000);   // <- 10 s for demo; change to 600 000 for 10 min
}
