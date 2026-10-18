# VitalTrack: AI-Powered Smart Health Watch

VitalTrack is a connected smartwatch for real-time health monitoring. An ESP32 reads physiological sensors and streams the data to Firebase; a Flutter mobile app displays it live, and a FastAPI backend serves machine-learning models that predict health indicators.

Academic project at ENET'Com Sfax (Jan–Apr 2025), developed with Yessin Soussi.

## Features

- Heart rate (BPM) and blood oxygen saturation (SpO₂) monitoring
- Blood pressure estimation and hypertension classification
- Glucose level estimation
- Physical activity recognition (walking, jogging, cycling)
- Health stability classification (Stable / Unstable / Grave)
- User authentication and real-time data visualization

## Architecture

```
 ESP32 + sensors  ──►  Firebase Realtime DB / Firestore  ──►  Flutter app
 (MAX30100, MPU6050,                                            │
  AD8232)                                                       ▼
                                                    FastAPI backend (ML models)
```

## Repository structure

```
vitaltrack/
├── firmware/      ESP32 firmware (Arduino)
├── mobile_app/    Flutter mobile application
├── backend/       FastAPI server exposing the prediction endpoints
└── ai_models/     Training notebooks and datasets
    ├── heart_rate/
    ├── hypertension/
    ├── diabetes/
    ├── physical_activity/
    └── stability/
```

## Tech stack

- **Hardware:** ESP32, MAX30100 (heart rate / SpO₂), MPU6050 (IMU), AD8232 (ECG)
- **Mobile:** Flutter, Firebase Auth, Firebase Realtime Database, Cloud Firestore
- **Backend:** FastAPI, NumPy, TensorFlow Lite
- **Machine learning:** scikit-learn (regression, Random Forest), TensorFlow / neural networks

## Getting started

### 1. Firmware (ESP32)

Open `firmware/progm_final/progm_final.ino` in the Arduino IDE and fill in your own credentials:

```cpp
#define WIFI_SSID ""
#define WIFI_PASSWORD ""
#define API_KEY ""
#define DATABASE_URL ""
```

### 2. Backend

The trained models are not included in this repository because of their size. Regenerate them by running the notebooks in `ai_models/`, then place the exported files in `backend/models/`:

| File | Source notebook |
|------|-----------------|
| `act_phy.pickle` | `ai_models/physical_activity/` |
| `diabete.pickle` | `ai_models/diabetes/` |
| `heart_rate.pickle` | `ai_models/heart_rate/` |
| `hypertension.pickle` | `ai_models/hypertension/` |
| `stability1.tflite` | already included |

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

| Endpoint | Description |
|----------|-------------|
| `POST /predict/heart_rate` | Heart rate prediction |
| `POST /predict/hypertension` | Blood pressure + category |
| `POST /predict/diabetes` | Glucose level prediction |
| `POST /predict/activity` | Physical activity class |
| `POST /predict/stability1` | Health stability class |

### 3. Mobile app

The Firebase configuration files are not included. Create your own Firebase project, then generate them with the FlutterFire CLI:

```bash
cd mobile_app
flutterfire configure
flutter pub get
flutter run
```

Set the backend address in `lib/services/api.dart` (`baseUrl`).
