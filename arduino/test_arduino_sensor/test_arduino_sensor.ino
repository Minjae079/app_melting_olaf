#include <OneWire.h>
#include <DallasTemperature.h>

constexpr int sensor1Pin = 2;
constexpr int sensor2Pin = 3;
constexpr unsigned long readingIntervalMs = 1000;

OneWire wire1(sensor1Pin);
OneWire wire2(sensor2Pin);
DallasTemperature sensor1(&wire1);
DallasTemperature sensor2(&wire2);

void printTwoDigits(unsigned long value) {
  if (value < 10) {
    Serial.print('0');
  }
  Serial.print(value);
}

void printElapsedTime() {
  const unsigned long totalSeconds = millis() / 1000;
  const unsigned long hours = totalSeconds / 3600;
  const unsigned long minutes = (totalSeconds % 3600) / 60;
  const unsigned long seconds = totalSeconds % 60;

  Serial.print('[');
  printTwoDigits(hours);
  Serial.print(':');
  printTwoDigits(minutes);
  Serial.print(':');
  printTwoDigits(seconds);
  Serial.println(']');
}

void printSensorResult(const char* name, int pin, DallasTemperature& sensor) {
  const int deviceCount = sensor.getDeviceCount();
  const float temperature = sensor.getTempCByIndex(0);

  Serial.print(name);
  Serial.print(" (D");
  Serial.print(pin);
  Serial.print(") | detected: ");
  Serial.print(deviceCount);
  Serial.print(" | ");

  if (deviceCount == 0 || temperature == DEVICE_DISCONNECTED_C) {
    Serial.println("ERROR: sensor not detected (-127 C)");
    return;
  }

  if (temperature == 85.0) {
    Serial.println("WARNING: 85 C startup/default reading");
    return;
  }

  Serial.print("temperature: ");
  Serial.print(temperature, 2);
  Serial.println(" C");
}

void setup() {
  Serial.begin(9600);
  sensor1.begin();
  sensor2.begin();

  Serial.println();
  Serial.println("=== DS18B20 sensor test ===");
  Serial.println("Time format: elapsed HH:MM:SS since startup");
  Serial.println("Sensor 1 data pin: D2");
  Serial.println("Sensor 2 data pin: D3");
  Serial.println("Expected: one detected device on each pin");
  Serial.println();
}

void loop() {
  sensor1.requestTemperatures();
  sensor2.requestTemperatures();

  printElapsedTime();
  printSensorResult("Sensor 1", sensor1Pin, sensor1);
  printSensorResult("Sensor 2", sensor2Pin, sensor2);
  Serial.println("----------------------------------------");

  delay(readingIntervalMs);
}
