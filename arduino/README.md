# Arduino sketches

## Supabase temperature uploader

Open `sketch_nov5a/sketch_nov5a.ino` in Arduino IDE. Before compiling, copy
`arduino_secrets.example.h` to `arduino_secrets.h` in the same directory and
replace the placeholders with the Wi-Fi credentials and device API key.

The real `arduino_secrets.h` is ignored by Git and must never be committed.

Required Arduino libraries:

- OneWire
- DallasTemperature
- WiFiS3 (included with the Arduino UNO R4 WiFi board package)

## Sensor-only test

Use `test_arduino_sensor/test_arduino_sensor.ino` to test the two DS18B20
sensors on D2 and D3 without Wi-Fi or Supabase.
