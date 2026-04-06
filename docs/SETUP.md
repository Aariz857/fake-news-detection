# Environment Setup Guide

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.10+ | Backend runtime |
| Flutter | 3.16+ | Mobile app framework |
| Tesseract OCR | 5.0+ | Text extraction from images |
| Git | 2.0+ | Version control |
| Android Studio | Latest | Android emulator & SDK |

---

## 1. Backend Setup

### Step 1: Clone & Navigate
```bash
cd "project deep/backend"
```

### Step 2: Create Virtual Environment
```bash
# Windows
py -m venv venv
.\venv\Scripts\activate

# Linux/Mac
python3 -m venv venv
source venv/bin/activate
```

### Step 3: Install Dependencies
```bash
# Core dependencies
pip install -r requirements.txt

# PyTorch CPU-only (lighter download)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
```

### Step 4: Install Tesseract OCR
**Windows:**
- Download installer from: https://github.com/UB-Mannheim/tesseract/wiki
- Install to default path: `C:\Program Files\Tesseract-OCR\`
- The app auto-detects this path

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install tesseract-ocr tesseract-ocr-eng
```

**Mac:**
```bash
brew install tesseract
```

### Step 5: Configure Environment
```bash
# Copy the example env file
cp .env.example .env

# Edit .env with your settings:
# MOCK_MODE=False   (uses real BERT model)
# MOCK_MODE=True    (uses heuristic mock — no model download needed)
```

### Step 6: Run Backend
```bash
# Development mode with hot-reload
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Or using Python directly
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Step 7: Verify
- Open http://localhost:8000/docs → Swagger UI
- Open http://localhost:8000/api/v1/health → Health check

---

## 2. Frontend Setup

### Step 1: Install Flutter SDK
Follow official guide: https://docs.flutter.dev/get-started/install

### Step 2: Navigate & Install Dependencies
```bash
cd "project deep/frontend"
flutter pub get
```

### Step 3: Configure API URL
Edit `lib/data/services/api_service.dart`:
```dart
// For Android emulator (default):
static const String _baseUrl = 'http://10.0.2.2:8000';

// For physical device (use your computer's IP):
static const String _baseUrl = 'http://192.168.x.x:8000';

// For iOS simulator:
static const String _baseUrl = 'http://localhost:8000';
```

### Step 4: Run on Android Emulator
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Or run on any available device
flutter run
```

---

## 3. API Keys (Optional — for live features)

### NewsAPI
1. Go to https://newsapi.org/register
2. Get free API key (100 requests/day)
3. Add to `.env`: `NEWSAPI_KEY=your_key_here`

### Google Custom Search
1. Go to https://console.cloud.google.com
2. Create project → Enable "Custom Search API"
3. Create credentials → API Key
4. Go to https://programmablesearchengine.google.com → Create engine
5. Add to `.env`:
   ```
   GOOGLE_API_KEY=your_key
   GOOGLE_CX_ID=your_engine_id
   ```

### OpenAI (ChatGPT)
1. Go to https://platform.openai.com/api-keys
2. Create new API key
3. Add to `.env`: `OPENAI_API_KEY=your_key_here`

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `python not found` | Use `py` on Windows or `python3` on Linux/Mac |
| `tesseract not found` | Install Tesseract and set `TESSERACT_CMD` in `.env` |
| `Connection refused` on phone | Use computer's local IP, not `localhost` |
| `cleartext not permitted` | Already configured in AndroidManifest.xml |
| Model download slow | First run downloads ~500MB BERT model; subsequent runs use cache |
| Out of memory | Set `MOCK_MODE=True` to skip model loading |
