#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <Wire.h>
#include "MAX30100_PulseOximeter.h"
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// Wi-Fi credentials
#define WIFI_SSID ""
#define WIFI_PASSWORD ""

// Firebase credentials
#define API_KEY ""
#define DATABASE_URL ""

// Firebase configuration
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

// MAX30100 Pulse Oximeter instance
PulseOximeter pox;

// AD8232 ECG sensor pin
const int adcPin = 35;

// MPU6050 instance
Adafruit_MPU6050 mpu;

// PCA9548A I2C address
#define PCA9548A_ADDR 0x70

// Select channel on PCA9548A
void selectI2CChannel(uint8_t channel) {
  if (channel > 7) return;
  Wire.beginTransmission(PCA9548A_ADDR);
  Wire.write(1 << channel);
  Wire.endTransmission();
}

unsigned long sendDataPrevMillis = 0;
unsigned long printInterval = 2000;
unsigned long dataInterval = 3000;
bool signupOK = false;

// ECG filter
#define ALPHA 0.1
float filteredECG = 0;
int threshold = 0;

// Auto-reset timer
unsigned long lastSensorResetTime = 0;
unsigned long sensorResetInterval = 5 * 60 * 1000; // 5 minutes

void onBeatDetected() {
  Serial.println("Beat detected!");
}

void setup() {
  Serial.begin(115200);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nConnected with IP: " + WiFi.localIP().toString());

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase authentication success.");
    signupOK = true;
  } else {
    Serial.printf("Firebase Sign-up Error: %s\n", config.signer.signupError.message.c_str());
  }
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Wire.begin(21, 22);
  Wire.setClock(100000);
  delay(100);

  // === Select MAX30100 channel ===
  selectI2CChannel(0);
  delay(100);
  Serial.print("Initializing Pulse Oximeter...");
  if (!pox.begin()) {
    Serial.println("FAILED!");
    while (1);
  }
  Serial.println("SUCCESS");
  pox.setIRLedCurrent(MAX30100_LED_CURR_50MA);
  pox.setOnBeatDetectedCallback(onBeatDetected);

  // === Select MPU6050 channel ===
  selectI2CChannel(1);
  delay(100);
  if (!mpu.begin()) {
    Serial.println("MPU6050 not detected! Check wiring.");
    while (1);
  }
  Serial.println("MPU6050 detected!");

  delay(2000);
  lastSensorResetTime = millis(); // Initialize reset timer
}

unsigned long lastPrintTime = 0;

void loop() {
  // === Select MAX30100 channel before updating ===
  selectI2CChannel(0);
  pox.update();

  float heartRate = pox.getHeartRate();
  float spo2 = pox.getSpO2();
  int ecgValue = analogRead(adcPin);
  unsigned long timestamp = millis() / 1000;

  filteredECG = (1 - ALPHA) * filteredECG + ALPHA * ecgValue;
  threshold = filteredECG * 1.1;
  int binaryECG = (ecgValue > threshold) ? 1 : 0;

  // === Select MPU6050 channel before reading ===
  selectI2CChannel(1);
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  float ax = a.acceleration.x;
  float ay = a.acceleration.y;
  float az = a.acceleration.z;
  float gx = g.gyro.x;
  float gy = g.gyro.y;
  float gz = g.gyro.z;

  if (millis() - lastPrintTime > printInterval) {
    lastPrintTime = millis();
    Serial.printf("HR: %.2f bpm | SpO2: %.2f %% | ECG: %d\n", heartRate, spo2, binaryECG);
    Serial.printf("Accel [%.2f, %.2f, %.2f] | Gyro [%.2f, %.2f, %.2f]\n", ax, ay, az, gx, gy, gz);
  }

  if (millis() - sendDataPrevMillis > dataInterval) {
    sendDataPrevMillis = millis();

    if (heartRate > 0 && spo2 > 0 && signupOK) {
      FirebaseJson json;
      json.set("heart_rate", heartRate);
      json.set("spo2", spo2);
      json.set("binary_ecg", binaryECG);
      json.set("timestamp", timestamp);
      json.set("accel_x", ax);
      json.set("accel_y", ay);
      json.set("accel_z", az);
      json.set("gyro_x", gx);
      json.set("gyro_y", gy);
      json.set("gyro_z", gz);

      if (Firebase.RTDB.setJSON(&firebaseData, "/health_data", &json)) {
        Serial.println("Data sent successfully!");
      } else {
        Serial.println("Error sending data to Firebase.");
        Serial.println(firebaseData.errorReason());
      }
    }
  }

  // 🔁 Auto-reset MAX30100 every 5 minutes
  if (millis() - lastSensorResetTime > sensorResetInterval) {
    Serial.println("🔁 Resetting MAX30100 sensor...");
    selectI2CChannel(0);
    pox.shutdown(); // Turn off
    delay(100);
    pox.begin();    // Re-initialize
    pox.setIRLedCurrent(MAX30100_LED_CURR_50MA);
    pox.setOnBeatDetectedCallback(onBeatDetected);
    lastSensorResetTime = millis();
  }
}

