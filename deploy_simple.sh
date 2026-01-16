#!/bin/bash

# Set variables
PROJECT_ID="prometheus-toolkit"
IMAGE_NAME="no-code-architects-toolkit"
REGION="us-central1"
SERVICE_NAME="nca-toolkit"
API_KEY="prometheus-toolkit-api-key"
BUCKET_NAME="prometheus-toolkit-bucket"

# Build the Docker image
echo "Building Docker image..."
docker build -t gcr.io/$PROJECT_ID/$IMAGE_NAME:latest .

# Configure Docker to use gcloud as a credential helper
echo "Configuring Docker to use gcloud as a credential helper..."
gcloud auth configure-docker

# Push the Docker image to Google Container Registry
echo "Pushing Docker image to Google Container Registry..."
docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:latest

# Deploy to Cloud Run with environment variables
# WHY: max-instances=10 and concurrency=40 prevent rate limiting
# WHY: min-instances=1 keeps one warm instance for faster cold starts
echo "Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image=gcr.io/$PROJECT_ID/$IMAGE_NAME:latest \
  --platform=managed \
  --region=$REGION \
  --memory=16Gi \
  --cpu=4 \
  --min-instances=1 \
  --max-instances=10 \
  --concurrency=40 \
  --allow-unauthenticated \
  --set-env-vars="API_KEY=$API_KEY,GCP_BUCKET_NAME=$BUCKET_NAME,GUNICORN_WORKERS=4"

# Get the service URL
echo "Getting the service URL..."
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform=managed --region=$REGION --format="value(status.url)")
echo "Service URL: $SERVICE_URL"

echo ""
echo "IMPORTANT: You need to manually set the GCP_SA_CREDENTIALS environment variable in the Cloud Run console:"
echo "1. Go to https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/revisions"
echo "2. Click on 'Edit & Deploy New Revision'"
echo "3. Scroll down to 'Container, Networking, Security'"
echo "4. Add the environment variable GCP_SA_CREDENTIALS with the contents of key.json"
echo "5. Click 'Deploy'" 