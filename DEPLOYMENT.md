# 🚀 ForensIQ Deployment Guide for Render

This guide provides step-by-step instructions for deploying the **ForensIQ Multimodal Forensics Application** (FastAPI Backend + Flutter Web Frontend) to [Render](https://render.com).

---

## 🛠️ Prerequisites

1. A [Render Account](https://dashboard.render.com/register).
2. Your repository pushed to GitHub or GitLab.

---

## Option 1: Automatic Blueprint Deployment (Recommended)

Render Blueprints use the [`render.yaml`](./render.yaml) specification in the root of your repository to automatically configure and link both the backend and frontend services.

### Steps:
1. Log into your [Render Dashboard](https://dashboard.render.com).
2. Click **New +** at the top right and select **Blueprint**.
3. Connect your Git repository containing `ForensIQ`.
4. Render will parse `render.yaml` and detect two services:
   - **`forensiq-backend`**: FastAPI Python Backend (Docker).
   - **`forensiq-frontend`**: Flutter Web Application (Docker + Nginx).
5. Click **Apply**.
6. Once deployment finishes, update the `API_BASE_URL` environment variable on `forensiq-frontend` to match your actual deployed backend URL (`https://forensiq-backend.onrender.com`).

---

## Option 2: Manual Web Service Setup

If you prefer to configure services manually in the Render dashboard:

### 1. Deploying Backend (`forensiq-backend`)

1. In Render Dashboard, click **New +** -> **Web Service**.
2. Select your repository.
3. Configure the settings:
   - **Name**: `forensiq-backend`
   - **Runtime**: `Docker`
   - **Dockerfile Path**: `./Dockerfile.backend`
   - **Docker Command Context**: `.`
   - **Instance Type**: Free / Starter
4. Environment Variables:
   - `PORT`: `8000`
   - `PYTHONUNBUFFERED`: `1`
5. Click **Create Web Service**.
6. Copy the deployed backend URL (e.g. `https://forensiq-backend.onrender.com`).

### 2. Deploying Frontend (`forensiq-frontend`)

#### Method A: Docker Web Service (Recommended)
1. Click **New +** -> **Web Service**.
2. Configure settings:
   - **Name**: `forensiq-frontend`
   - **Runtime**: `Docker`
   - **Dockerfile Path**: `./Dockerfile.frontend`
   - **Docker Command Context**: `.`
3. Environment Variables / Build Arguments:
   - `API_BASE_URL`: `https://forensiq-backend.onrender.com` (Your deployed backend URL)
4. Click **Create Web Service**.

#### Method B: Render Static Site (Alternative)
1. In your local terminal, build the Flutter Web release bundle:
   ```bash
   cd frontend
   flutter build web --release --dart-define=API_BASE_URL=https://forensiq-backend.onrender.com
   ```
2. In Render Dashboard, click **New +** -> **Static Site**.
3. Configure:
   - **Build Command**: `cd frontend && flutter build web --release --dart-define=API_BASE_URL=https://forensiq-backend.onrender.com`
   - **Publish Directory**: `./frontend/build/web`

---

## 🔍 Post-Deployment Health Check

1. **Verify Backend Health**:
   Visit `https://<your-backend-url>.onrender.com/health` in your browser.
   Expected response:
   ```json
   {
     "status": "healthy",
     "services": {
       "part1_gateway": true,
       "part3_pipeline": true,
       "part4_ensemble": true,
       "deepfake_pipeline": true
     }
   }
   ```

2. **Verify Frontend UI**:
   Visit `https://<your-frontend-url>.onrender.com`.
   The ForensIQ dashboard should load smoothly and communicate with the backend.

---

## 📋 Included Deployment Files Summary

| File | Purpose |
| --- | --- |
| [`render.yaml`](./render.yaml) | Render Blueprint defining backend and frontend services |
| [`Dockerfile.backend`](./Dockerfile.backend) | Docker container for FastAPI + OpenCV + PyTorch + MediaPipe |
| [`Dockerfile.frontend`](./Dockerfile.frontend) | Multi-stage Docker container compiling and serving Flutter Web |
| [`nginx.conf`](./nginx.conf) | Nginx SPA configuration and caching rules for Flutter Web |
| [`Procfile`](./Procfile) | Standard Heroku/Render process file |
| [`.dockerignore`](./.dockerignore) / [`.renderignore`](./.renderignore) | Optimization rules to skip unnecessary files during build |
