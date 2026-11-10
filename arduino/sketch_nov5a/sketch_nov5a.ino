#include <WiFiS3.h>
#include <OneWire.h>
#include <DallasTemperature.h>

#include "arduino_secrets.h"

constexpr int sensor1Pin = 2;
constexpr int sensor2Pin = 3;
constexpr unsigned long uploadIntervalMs = 1000;
constexpr unsigned long sessionRetryIntervalMs = 5000;

const char supabaseHost[] = "pimrwslkvqumueidurir.supabase.co";
const char supabasePath[] = "/functions/v1/ingest-temperature";
const char deviceId[] = "olaf-01";

OneWire wire1(sensor1Pin);
OneWire wire2(sensor2Pin);
DallasTemperature sensor1(&wire1);
DallasTemperature sensor2(&wire2);

String activeSessionId;
unsigned long sampleIndex = 0;
unsigned long lastUploadAt = 0;
unsigned long lastSessionAttemptAt = 0;

bool isValidTemperature(float value) {
  return value != DEVICE_DISCONNECTED_C && !isnan(value) &&
         value >= -55.0 && value <= 125.0;
}

void connectWiFi() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.print("Connecting to Wi-Fi");

    while (WiFi.status() != WL_CONNECTED) {
      WiFi.begin(SECRET_SSID, SECRET_PASS);

      for (int attempt = 0; attempt < 10; attempt++) {
        if (WiFi.status() == WL_CONNECTED) {
          break;
        }
        Serial.print(".");
        delay(500);
      }
    }
    Serial.println();
  }

  const IPAddress emptyIp(0, 0, 0, 0);
  const unsigned long dhcpStartedAt = millis();

  while (WiFi.localIP() == emptyIp && millis() - dhcpStartedAt < 10000) {
    delay(100);
  }

  Serial.print("Wi-Fi connected. IP: ");
  Serial.println(WiFi.localIP());
}

int postToSupabase(const String& payload, String& responseBody) {
  WiFiSSLClient client;
  client.setTimeout(5000);

  if (!client.connect(supabaseHost, 443)) {
    Serial.println("Supabase TLS connection failed");
    return 0;
  }

  client.print("POST ");
  client.print(supabasePath);
  client.println(" HTTP/1.1");
  client.print("Host: ");
  client.println(supabaseHost);
  client.println("Content-Type: application/json");
  client.print("X-Device-Key: ");
  client.println(SECRET_DEVICE_API_KEY);
  client.print("Content-Length: ");
  client.println(payload.length());
  client.println("Connection: close");
  client.println();
  client.print(payload);

  const unsigned long responseStartedAt = millis();

  while (!client.available() && client.connected()) {
    if (millis() - responseStartedAt > 5000) {
      Serial.println("Supabase response timed out");
      client.stop();
      return 0;
    }
  }

  String statusLine = client.readStringUntil('\n');
  statusLine.trim();
  Serial.print("Supabase response: ");
  Serial.println(statusLine);

  String response;
  unsigned long lastResponseAt = millis();

  while (client.connected() || client.available()) {
    while (client.available()) {
      response += static_cast<char>(client.read());
      lastResponseAt = millis();
    }
    if (millis() - lastResponseAt > 5000) {
      break;
    }
  }

  client.stop();
  const int bodyStart = response.indexOf("\r\n\r\n");
  responseBody = bodyStart >= 0 ? response.substring(bodyStart + 4) : response;

  if (!statusLine.startsWith("HTTP/") || statusLine.length() < 12) {
    return 0;
  }
  return statusLine.substring(9, 12).toInt();
}

String extractJsonString(const String& json, const char* key) {
  String marker = "\"";
  marker += key;
  marker += "\":\"";

  const int valueStart = json.indexOf(marker);
  if (valueStart < 0) {
    return "";
  }

  const int contentStart = valueStart + marker.length();
  const int contentEnd = json.indexOf('"', contentStart);
  if (contentEnd < 0) {
    return "";
  }
  return json.substring(contentStart, contentEnd);
}

bool startExperimentSession() {
  const bool sensor1Present = sensor1.getDeviceCount() > 0;
  const bool sensor2Present = sensor2.getDeviceCount() > 0;

  String payload = "{\"action\":\"start\",\"deviceId\":\"";
  payload += deviceId;
  payload += "\",\"sessionName\":\"Arduino experiment\"";
  payload += ",\"sensor1Present\":";
  payload += sensor1Present ? "true" : "false";
  payload += ",\"sensor2Present\":";
  payload += sensor2Present ? "true" : "false";
  payload += "}";

  String responseBody;
  const int statusCode = postToSupabase(payload, responseBody);

  if (statusCode != 201) {
    Serial.print("Session creation failed: ");
    Serial.println(responseBody);
    return false;
  }

  activeSessionId = extractJsonString(responseBody, "sessionId");
  if (activeSessionId.length() != 36) {
    Serial.println("Session response did not contain a valid sessionId");
    activeSessionId = "";
    return false;
  }

  sampleIndex = 0;
  lastUploadAt = 0;
  Serial.print("Experiment session started: ");
  Serial.println(activeSessionId);
  return true;
}

int uploadTemperatureSample(float temperature1, float temperature2) {
  const bool sensor1Valid = isValidTemperature(temperature1);
  const bool sensor2Valid = isValidTemperature(temperature2);

  if (!sensor1Valid && !sensor2Valid) {
    Serial.println("No valid sensors; upload skipped");
    return 0;
  }

  String payload = "{\"deviceId\":\"";
  payload += deviceId;
  payload += "\",\"sessionId\":\"";
  payload += activeSessionId;
  payload += "\",\"sampleIndex\":";
  payload += String(sampleIndex);
  payload += ",\"sensor1\":";
  if (sensor1Valid) {
    payload += String(temperature1, 2);
  } else {
    payload += "null";
  }
  payload += ",\"sensor2\":";
  if (sensor2Valid) {
    payload += String(temperature2, 2);
  } else {
    payload += "null";
  }
  payload += "}";

  String responseBody;
  const int statusCode = postToSupabase(payload, responseBody);

  if (statusCode == 201) {
    Serial.print("Sample stored: ");
    Serial.println(sampleIndex);
    sampleIndex++;
  } else {
    Serial.print("Sample upload failed: ");
    Serial.println(responseBody);
  }
  return statusCode;
}

void setup() {
  Serial.begin(9600);
  sensor1.begin();
  sensor2.begin();
  connectWiFi();
  startExperimentSession();
}

void loop() {
  connectWiFi();

  if (activeSessionId.length() == 0) {
    const unsigned long now = millis();
    if (now - lastSessionAttemptAt >= sessionRetryIntervalMs) {
      lastSessionAttemptAt = now;
      startExperimentSession();
    }
    delay(50);
    return;
  }

  const unsigned long now = millis();
  if (lastUploadAt != 0 && now - lastUploadAt < uploadIntervalMs) {
    delay(20);
    return;
  }

  lastUploadAt = now;
  sensor1.requestTemperatures();
  sensor2.requestTemperatures();

  const float temperature1 = sensor1.getTempCByIndex(0);
  const float temperature2 = sensor2.getTempCByIndex(0);

  Serial.print("Sensor1: ");
  Serial.print(temperature1, 2);
  Serial.print(" C\tSensor2: ");
  Serial.print(temperature2, 2);
  Serial.println(" C");

  const int statusCode = uploadTemperatureSample(temperature1, temperature2);
  if (statusCode == 404 || statusCode == 409) {
    Serial.println("Session is no longer active; starting a new session");
    activeSessionId = "";
  }
}
