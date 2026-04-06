# Deployment Guide

## Option 1: Local Development (Current)

### Backend
```bash
cd backend
.\venv\Scripts\activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend
```bash
cd frontend
flutter run
```

---

## Option 2: Docker (Recommended for Staging)

### Build & Run
```bash
cd backend

# Build image
docker build -t fakenews-backend .

# Run container
docker run -d \
  --name fakenews-backend \
  -p 8000:8000 \
  -e MOCK_MODE=False \
  -e USE_GPU=False \
  fakenews-backend
```

### Using Docker Compose
```bash
cd backend
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

---

## Option 3: Google Cloud Run (Production)

### Prerequisites
1. Install [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
2. Create a GCP project: `gcloud projects create fakenews-detector`
3. Enable Cloud Run: `gcloud services enable run.googleapis.com`

### Deploy

```bash
cd backend

# Authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Build and push to Container Registry
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/fakenews-backend

# Deploy to Cloud Run
gcloud run deploy fakenews-backend \
  --image gcr.io/YOUR_PROJECT_ID/fakenews-backend \
  --platform managed \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 120 \
  --max-instances 3 \
  --set-env-vars "MOCK_MODE=False,USE_GPU=False" \
  --allow-unauthenticated
```

### Set Environment Variables (Secrets)
```bash
# Create secrets
echo -n "your_newsapi_key" | gcloud secrets create NEWSAPI_KEY --data-file=-
echo -n "your_openai_key" | gcloud secrets create OPENAI_API_KEY --data-file=-

# Attach to Cloud Run
gcloud run services update fakenews-backend \
  --set-secrets "NEWSAPI_KEY=NEWSAPI_KEY:latest,OPENAI_API_KEY=OPENAI_API_KEY:latest"
```

### Update Flutter App
After deploying, update your Flutter app's API URL:
```dart
// lib/data/services/api_service.dart
static const String _baseUrl = 'https://fakenews-backend-xxxxx-uc.a.run.app';
```

---

## Option 4: AWS (Alternative)

### Using AWS App Runner
```bash
# Install AWS CLI and configure credentials
aws configure

# Build Docker image
docker build -t fakenews-backend .

# Push to ECR
aws ecr create-repository --repository-name fakenews-backend
docker tag fakenews-backend:latest YOUR_ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/fakenews-backend
docker push YOUR_ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/fakenews-backend

# Deploy with App Runner (via AWS Console or CLI)
```

---

## Flutter App Build (Android APK)

### Debug APK (for testing)
```bash
cd frontend
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (for distribution)
```bash
cd frontend

# Generate keystore (first time only)
keytool -genkey -v -keystore ~/fakenews-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle (for Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## Production Checklist

- [ ] Set `MOCK_MODE=False` for real BERT inference
- [ ] Set `DEBUG=False` for production logging
- [ ] Configure all API keys (NewsAPI, Google CSE, OpenAI)
- [ ] Set specific `CORS_ORIGINS` (not `*`)
- [ ] Add API key authentication
- [ ] Set up monitoring (Cloud Monitoring / CloudWatch)
- [ ] Configure Firebase Analytics in Flutter app
- [ ] Set minimum memory to 2GB for model inference
- [ ] Test with production images and verify accuracy
- [ ] Set up CI/CD pipeline (GitHub Actions)
