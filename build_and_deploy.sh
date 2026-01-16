#!/bin/bash

# Set variables
PROJECT_ID="prometheus-toolkit"
IMAGE_NAME="no-code-architects-toolkit"
REGION="us-central1"
SERVICE_NAME="nca-toolkit"

# Step 1: Push the Docker image to Google Container Registry
echo "Pushing Docker image to Google Container Registry..."
gcloud auth configure-docker
docker push gcr.io/$PROJECT_ID/$IMAGE_NAME:latest

# Step 2: Deploy to Cloud Run with extended timeout using env.yaml
echo "Deploying to Cloud Run..."
# WHY: max-instances=10 prevents rate limiting when multiple video jobs run concurrently
# WHY: concurrency=40 balances throughput with resource usage per instance
# WHY: GUNICORN_WORKERS=4 allows more parallel request handling per container
gcloud run deploy $SERVICE_NAME \
  --image=gcr.io/$PROJECT_ID/$IMAGE_NAME:latest \
  --platform=managed \
  --region=$REGION \
  --memory=16Gi \
  --cpu=8 \
  --timeout=900 \
  --min-instances=1 \
  --max-instances=10 \
  --concurrency=40 \
  --allow-unauthenticated \
  --set-env-vars="GUNICORN_WORKERS=4" \
  --env-vars-file=env.yaml

echo "Deployment completed. Now set the GCP_SA_CREDENTIALS in the Cloud Run console."
echo "1. Go to https://console.cloud.google.com/run"
echo "2. Select your service (nca-toolkit)"
echo "3. Click 'Edit & Deploy New Revision'"
echo "4. Under 'Container, Networking, Security', add the environment variable:"
echo "   - Name: GCP_SA_CREDENTIALS"
echo "   - Value: [Copy and paste the entire contents of key.json]"
echo "5. Click 'Deploy'"

# Get the service URL
echo "Getting service URL..."
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform=managed --region=$REGION --format="value(status.url)")
echo "Service URL: $SERVICE_URL" 