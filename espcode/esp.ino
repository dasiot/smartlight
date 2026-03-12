#include <WiFi.h>
#include <WebServer.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "BluetoothSerial.h" 
// =====================================================
//  LED PIN
// =====================================================
#define LED_PIN 2

// =====================================================
//  WiFi HOTSPOT SETTINGS
// =====================================================
const char* ssid     = "ESP32_LED_Control";
const char* password = "12345678";

// =====================================================
//  BLE UUIDs
// =====================================================
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// =====================================================
//  GLOBALS
// =====================================================
BLEServer*         pServer         = NULL;
BLECharacteristic* pCharacteristic = NULL;
WebServer          server(80);
BluetoothSerial    SerialBT;        // 🔵 Bluetooth Classic object
bool               bleConnected    = false;

// =====================================================
//  HTML PAGE 
// =====================================================
String webpage = R"====( 
<!DOCTYPE html>
<html>
<head>
  <title>ESP32 LED Control</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body {
      font-family: Arial;
      text-align: center;
      background: linear-gradient(135deg, #667eea, #764ba2);
      color: white;
      margin-top: 50px;
    }
    .card {
      background: white;
      color: black;
      width: 300px;
      margin: auto;
      padding: 30px;
      border-radius: 20px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.3);
    }
    .switch {
      position: relative;
      display: inline-block;
      width: 80px;
      height: 40px;
    }
    .switch input { display: none; }
    .slider {
      position: absolute;
      cursor: pointer;
      background-color: #ccc;
      border-radius: 40px;
      top: 0; left: 0; right: 0; bottom: 0;
      transition: .4s;
    }
    .slider:before {
      position: absolute;
      content: "";
      height: 30px;
      width: 30px;
      left: 5px;
      bottom: 5px;
      background-color: white;
      border-radius: 50%;
      transition: .4s;
    }
    input:checked + .slider { background-color: #4CAF50; }
    input:checked + .slider:before { transform: translateX(40px); }
  </style>
</head>
<body>
  <div class="card">
    <h2>ESP32 LED Control</h2>
    <label class="switch">
      <input type="checkbox" onchange="toggleLED(this)">
      <span class="slider"></span>
    </label>
    <p id="status">LED OFF</p>
  </div>
  <script>
    function toggleLED(element) {
      if (element.checked) {
        fetch("/led/on");
        document.getElementById("status").innerHTML = "LED ON";
      } else {
        fetch("/led/off");
        document.getElementById("status").innerHTML = "LED OFF";
      }
    }
  </script>
</body>
</html>
)====";

// =====================================================
//  BLE SERVER CALLBACKS
// =====================================================
class ServerCallbacks : public BLEServerCallbacks {

  void onConnect(BLEServer* pServer) {
    bleConnected = true;
    Serial.println("[ BLE  ] Client connected");
  }

  void onDisconnect(BLEServer* pServer) {
    bleConnected = false;
    Serial.println("[ BLE  ] Client disconnected");
    delay(500);
    BLEDevice::startAdvertising();
    Serial.println("[ BLE  ] Advertising restarted");
  }
};

// =====================================================
//  BLE WRITE CALLBACKS
// =====================================================
class CharCallbacks : public BLECharacteristicCallbacks {

  void onWrite(BLECharacteristic* pCharacteristic) {
    std::string val = pCharacteristic->getValue();

    if (val.length() > 0) {
      Serial.print("[ BLE  ] Received: ");
      Serial.println(val.c_str());

      if (val == "1") {
        digitalWrite(LED_PIN, HIGH);
        Serial.println("[ BLE  ] LED ON");
      }
      else if (val == "0") {
        digitalWrite(LED_PIN, LOW);
        Serial.println("[ BLE  ] LED OFF");
      }
      else {
        Serial.println("[ BLE  ] Unknown command");
      }
    }
  }
};

// =====================================================
//  BLUETOOTH CLASSIC HANDLER
// =====================================================
void handleBluetoothClassic() {

  if (SerialBT.available()) {
    char incoming = SerialBT.read();

    Serial.print("[ BT   ] Received: ");
    Serial.println(incoming);

    if (incoming == '1') {
      digitalWrite(LED_PIN, HIGH);
      Serial.println("[ BT   ] LED ON");
      SerialBT.println("LED ON");
    }
    else if (incoming == '0') {
      digitalWrite(LED_PIN, LOW);
      Serial.println("[ BT   ] LED OFF");
      SerialBT.println("LED OFF");
    }
    else {
      Serial.println("[ BT   ] Unknown command");
      SerialBT.println("Send 1 for ON, 0 for OFF");
    }
  }
}

// =====================================================
//  CORS HEADERS
// =====================================================
void sendCORSHeaders() {
  server.sendHeader("Access-Control-Allow-Origin",  "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

// =====================================================
//  HTTP HANDLERS
// =====================================================
void handleRoot() {
  sendCORSHeaders();
  server.send(200, "text/html", webpage);
}

void handleLEDOn() {
  digitalWrite(LED_PIN, HIGH);
  sendCORSHeaders();
  server.send(200, "text/plain", "LED ON");
  Serial.println("[ WiFi ] LED ON");
}

void handleLEDOff() {
  digitalWrite(LED_PIN, LOW);
  sendCORSHeaders();
  server.send(200, "text/plain", "LED OFF");
  Serial.println("[ WiFi ] LED OFF");
}

void handleOptions() {
  sendCORSHeaders();
  server.send(204);
}

// =====================================================
//  INIT BLE
// =====================================================
void initBLE() {
  BLEDevice::init("ESP32_LED");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ     |
    BLECharacteristic::PROPERTY_WRITE    |
    BLECharacteristic::PROPERTY_WRITE_NR
  );

  pCharacteristic->setCallbacks(new CharCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising* pAdv = BLEDevice::getAdvertising();
  pAdv->addServiceUUID(SERVICE_UUID);
  pAdv->setScanResponse(true);
  pAdv->setMinPreferred(0x06);
  pAdv->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("[ BLE  ] Initialized — name: ESP32_LED");
  Serial.println("[ BLE  ] Advertising started");
}

// =====================================================
//  SETUP
// =====================================================
void setup() {
  Serial.begin(115200);
    // ── Bluetooth Classic ──
  SerialBT.begin("ESP32_BT_CLASSIC");
  Serial.println("[ BT   ] Bluetooth Classic started");
  Serial.println("[ BT   ] Device name: ESP32_BT_CLASSIC");
  delay(1000);

  Serial.println();
  Serial.println("==========================================");
  Serial.println("  ESP32  BLE + WiFi Hotspot Controller   ");
  Serial.println("==========================================");

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  Serial.println("[ SYS  ] LED pin ready (GPIO 2)");

  // ── WiFi Hotspot ──
  WiFi.softAP(ssid, password);
  Serial.println("[ WiFi ] Hotspot started!");
  Serial.print  ("[ WiFi ] SSID      : ");
  Serial.println(ssid);
  Serial.print  ("[ WiFi ] Password  : ");
  Serial.println(password);
  Serial.print  ("[ WiFi ] IP Address: ");
  Serial.println(WiFi.softAPIP());

  // ── HTTP Routes ──
  server.on("/",        HTTP_GET,     handleRoot);
  server.on("/led/on",  HTTP_GET,     handleLEDOn);
  server.on("/led/off", HTTP_GET,     handleLEDOff);
  server.on("/led/on",  HTTP_OPTIONS, handleOptions);
  server.on("/led/off", HTTP_OPTIONS, handleOptions);
  server.on("/",        HTTP_OPTIONS, handleOptions);
  server.begin();
  Serial.println("[ WiFi ] Web server started on port 80");
  Serial.print  ("[ WiFi ] Open browser: http://");
  Serial.println(WiFi.softAPIP());

  // ── BLE ──
  initBLE();

  Serial.println("==========================================");
  Serial.println("[ SYS  ] Ready!");
  Serial.println("[ SYS  ] BLE  → scan 'ESP32_LED' in Flutter app");
  Serial.println("[ SYS  ] WiFi → connect to hotspot, open browser");
  Serial.println("==========================================");
}

// =====================================================
//  LOOP
// =====================================================
void loop() {
  server.handleClient();
  handleBluetoothClassic();   // 🔵 Added
  // Status heartbeat every 5 seconds
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint >= 5000) {
    lastPrint = millis();
    Serial.print("[ SYS  ] BLE: ");
    Serial.print(bleConnected ? "Connected" : "Waiting");
    Serial.print("  |  WiFi clients: ");
    Serial.print(WiFi.softAPgetStationNum());
    Serial.print("  |  LED: ");
    Serial.println(digitalRead(LED_PIN) == HIGH ? "ON" : "OFF");
  }
}