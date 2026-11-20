/*
 ==============================================================================
   ARENA POS — ESP32 + 4-KANALLI WI-FI RELE MIKRODASTURI (FIRMWARE)
 ==============================================================================
   Tavsif:
   Ushbu dastur 4 ta bilyard stoli chiroqlarini Wi-Fi orqali internetsiz
   va uzluksiz boshqarish uchun mo'ljallangan.

   Xususiyatlari:
   1. AP+STA ikkala rejimda ishlaydi:
      - Agar bilyardxonangizda Wi-Fi router bo'lsa, o'sha routerga ulanadi.
      - Agar router bo'lmasa yoki o'chiq bo'lsa, ESP32 O'ZI "Arena-Relay"
        nomli Wi-Fi tarqatadi! Telefonni shunga ulasangiz, 100% internetsiz ishlaydi.
   2. IP manzillar:
      - Routersiz (ESP32 o'z Wi-Fi tarqatganda): 192.168.4.1
      - Routerga ulanganda: Router bergan IP (yoki statik 192.168.1.100)
   3. REST API Buyruqlari:
      - http://<IP>/relay/1/on   -> 1-stol chirog'ini yoqish
      - http://<IP>/relay/1/off  -> 1-stol chirog'ini o'chirish
      - http://<IP>/relay/2/on   va  /off
      - http://<IP>/relay/3/on   va  /off
      - http://<IP>/relay/4/on   va  /off
      - http://<IP>/status       -> Hozirgi barcha holatlar (JSON)
      - http://<IP>/ping         -> Aloqani tekshirish

 ==============================================================================
   SIMLARNI ULASH SXEMASI (PIN-MAP):
 ==============================================================================
   ESP32 DevKit          4-Kanalli Rele Moduli
   -------------         ---------------------
   GND             --->  GND (Qora sim)
   VIN (yoki 5V)   --->  VCC (Qizil sim)
   GPIO 23 (D23)   --->  IN1 (1-bilyard stoli)
   GPIO 22 (D22)   --->  IN2 (2-bilyard stoli)
   GPIO 21 (D21)   --->  IN3 (3-bilyard stoli)
   GPIO 19 (D19)   --->  IN4 (4-bilyard stoli)

   220V Chiroqlarni ulash:
   Har bir relening 3 ta teshigi bor: [NO]  [COM]  [NC]
   - Tokdagi 220V faza simini [COM] ga ulang.
   - Lampochkaga ketadigan simni [NO] ga ulang.
 ==============================================================================
*/

#include <WiFi.h>
#include <WebServer.h>

// ── 1. ROUTER SOZLAMALARI (Agar zalingizda router bo'lsa kiriting) ──
const char* router_ssid     = "Arena_WiFi";    // Bilyardxona Wi-Fi nomi
const char* router_password = "parol_shu_yerda"; // Wi-Fi paroli

// ── 2. O'Z WI-FI TARMOg'I (Routersiz mustaqil ishlash uchun) ─────────
const char* ap_ssid         = "Arena-Relay";
const char* ap_password     = "12345678";

// ── 3. RELE PINLARI ──────────────────────────────────────────────────
const int RELAY_1 = 23; // 1-stol
const int RELAY_2 = 22; // 2-stol
const int RELAY_3 = 21; // 3-stol
const int RELAY_4 = 19; // 4-stol

// Relelarning ko'pchiligi LOW bo'lganda yoqiladi (Active LOW)
#define RELAY_ON  LOW
#define RELAY_OFF HIGH

WebServer server(80);

bool relay1_state = false;
bool relay2_state = false;
bool relay3_state = false;
bool relay4_state = false;

void setRelay(int channel, bool state) {
  int pin;
  switch (channel) {
    case 1: pin = RELAY_1; relay1_state = state; break;
    case 2: pin = RELAY_2; relay2_state = state; break;
    case 3: pin = RELAY_3; relay3_state = state; break;
    case 4: pin = RELAY_4; relay4_state = state; break;
    default: return;
  }
  digitalWrite(pin, state ? RELAY_ON : RELAY_OFF);
  Serial.printf("💡 [Arena] Rele %d -> %s\n", channel, state ? "YOQILDI" : "O'CHIRILDI");
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n🚀 ARENA POS — ESP32 Rele Tizimi Ishga Tushmoqda...");

  // Pinlarni chiqish rejimiga sozlash va barcha chiroqlarni boshida o'chirish
  pinMode(RELAY_1, OUTPUT);
  pinMode(RELAY_2, OUTPUT);
  pinMode(RELAY_3, OUTPUT);
  pinMode(RELAY_4, OUTPUT);

  digitalWrite(RELAY_1, RELAY_OFF);
  digitalWrite(RELAY_2, RELAY_OFF);
  digitalWrite(RELAY_3, RELAY_OFF);
  digitalWrite(RELAY_4, RELAY_OFF);

  // 1. O'z Wi-Fi tarmog'ini tarqatish (Har doim ochiq bo'ladi)
  WiFi.mode(WIFI_AP_STA);
  WiFi.softAP(ap_ssid, ap_password);
  Serial.printf("📶 ESP32 o'z Wi-Fi tarmog'ini ochdi: %s (IP: %s)\n", ap_ssid, WiFi.softAPIP().toString().c_str());

  // 2. Agar router ma'lumotlari kiritilgan bo'lsa, unga ulanish
  if (String(router_ssid) != "Arena_WiFi" || String(router_password) != "parol_shu_yerda") {
    Serial.printf("🌐 Routerga ulanmoqda: %s ...\n", router_ssid);
    WiFi.begin(router_ssid, router_password);
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 15) {
      delay(500);
      Serial.print(".");
      attempts++;
    }
    if (WiFi.status() == WL_CONNECTED) {
      Serial.printf("\n✅ Routerga muvaffaqiyatli ulandi! Router IP: %s\n", WiFi.localIP().toString().c_str());
    } else {
      Serial.println("\n⚠️ Routerga ulanib bo'lmadi. Faqat 'Arena-Relay' tarmog'i orqali ishlayveradi (192.168.4.1).");
    }
  }

  // ── WebServer Marshrutlari ──
  server.on("/ping", HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", "{\"status\":\"online\",\"device\":\"Arena-ESP32-Relay\",\"version\":\"2.0\"}");
  });

  server.on("/status", HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    String json = "{";
    json += "\"status\":\"ok\",";
    json += "\"relay1\":" + String(relay1_state ? "true" : "false") + ",";
    json += "\"relay2\":" + String(relay2_state ? "true" : "false") + ",";
    json += "\"relay3\":" + String(relay3_state ? "true" : "false") + ",";
    json += "\"relay4\":" + String(relay4_state ? "true" : "false");
    json += "}";
    server.send(200, "application/json", json);
  });

  // Relelarni boshqarish: /relay/<1..4>/<on|off>
  server.on(UriRegex("^\\/relay\\/([1-4])\\/(on|off)$"), HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    String chStr = server.pathArg(0);
    String stateStr = server.pathArg(1);
    int channel = chStr.toInt();
    bool state = (stateStr == "on");

    setRelay(channel, state);
    server.send(200, "application/json", "{\"success\":true,\"channel\":" + String(channel) + ",\"state\":\"" + stateStr + "\"}");
  });

  server.onNotFound([]() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(404, "text/plain", "Arena POS Rele Server: Buyruq topilmadi");
  });

  server.begin();
  Serial.println("🎉 Server muvaffaqiyatli ishga tushdi! Arena POS ilovasi orqali buyruqlarni qabul qilishga tayyor.");
}

void loop() {
  server.handleClient();
  delay(2);
}
