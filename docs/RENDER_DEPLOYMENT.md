# ShikkhaAI Backend - Render Deployment Guide

## Overview
This guide walks you through deploying the ShikkhaAI FastAPI backend on Render.com.

## Prerequisites
- Render.com account (free tier supports basic deployment)
- GitHub repository with the code
- Gemini API key (from https://ai.google.dev)
- (Optional) RAG service deployed elsewhere

## Step-by-Step Deployment

### 1. Prepare Your Repository

Ensure you have committed all changes:
```bash
git add .
git commit -m "chore: prepare backend for production deployment"
git push origin main
```

Key files that should be present:
- ✅ `Procfile` - Startup command for Render
- ✅ `pyproject.toml` - Python version requirements
- ✅ `backend/requirements.txt` - Python dependencies
- ✅ `backend/.env.example` - Environment variables documentation

### 2. Create PostgreSQL Database on Render

1. Go to https://dashboard.render.com
2. Click **"New" → "PostgreSQL"**
3. Fill in:
   - **Name**: `shikkhaai-db` (or your preferred name)
   - **Database**: `shikkhaai`
   - **User**: Choose a strong username
   - **Region**: Same as your service (e.g., Singapore)
   - **Plan**: Free tier is fine for starting

4. Click **"Create Database"**
5. Wait for database to provision (~2 minutes)
6. Copy the **Internal Database URL** (looks like: `postgresql://user:pass@hostname/shikkhaai`)
   - **Note**: Use the "Internal Database URL" for the backend service

### 3. Create Web Service on Render

1. Go to https://dashboard.render.com
2. Click **"New" → "Web Service"**
3. Connect your GitHub repository:
   - Select your ShikkhaAI repository
   - Click **"Connect"**

4. Configure the service:
   - **Name**: `shikkhaai-backend` (or preferred name)
   - **Environment**: `Docker` (or select `Python` if using Procfile)
   - **Region**: Same as database (e.g., Singapore)
   - **Branch**: `main` (or your deployment branch)
   - **Build Command**: (Leave empty or use default)
   - **Start Command**: Leave empty (uses Procfile)
   - **Plan**: Free tier for development

5. Click **"Create Web Service"**

### 4. Configure Environment Variables

After creating the service:

1. Go to the service dashboard → **Environment** tab
2. Add the following environment variables:

```
ENVIRONMENT=production
DATABASE_URL=<paste Internal Database URL from step 2>
GEMINI_API_KEY=<your-gemini-api-key>
CORS_ORIGINS=https://<your-frontend-domain>.onrender.com
MOCK_MODE=false
DEBUG=false
RAG_TIMEOUT_SECONDS=60
```

#### Detailed Explanations:

| Variable | Value | Notes |
|----------|-------|-------|
| `ENVIRONMENT` | `production` | Enables production safety checks |
| `DATABASE_URL` | PostgreSQL URL from step 2 | **Critical**: Use Internal URL |
| `GEMINI_API_KEY` | Your API key | Get from https://ai.google.dev |
| `CORS_ORIGINS` | `https://your-frontend.onrender.com` | Frontend domain only |
| `MOCK_MODE` | `false` | Use real AI generation |
| `DEBUG` | `false` | Disable debug logging |
| `RAG_BASE_URL` | (Optional) | Set if RAG service deployed elsewhere |
| `RAG_TIMEOUT_SECONDS` | `60` | Timeout for RAG requests |

### 5. Deploy

1. Render automatically deploys when you push to your branch
2. Monitor deployment in the **Logs** tab:
   - Building Python environment
   - Installing dependencies
   - Starting application

3. **Expected startup output**:
```
Logging initialized | Environment: production | Debug: False
Database initialized successfully
Started server process [12345]
Application startup complete
Uvicorn running on 0.0.0.0:10000
```

4. When complete, you should see **"Live"** badge on your service

### 6. Test Deployment

Once deployed, test your backend:

```bash
# Health check
curl https://<your-service>.onrender.com/health

# Expected response:
{
  "success": true,
  "data": {
    "status": "ok",
    "environment": "production",
    "mock_mode": false
  },
  "error": null
}

# Readiness check
curl https://<your-service>.onrender.com/ready

# Test student registration (with mock exam generation)
curl -X POST https://<your-service>.onrender.com/student/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Student",
    "email": "test@example.com",
    "grade_level": "8"
  }'
```

## Troubleshooting

### Issue: "DATABASE_URL is required"
**Solution**: Ensure `DATABASE_URL` is set in Environment variables. Use the **Internal** Database URL, not External.

### Issue: "CORS_ORIGINS cannot be '*' in production"
**Solution**: Set `CORS_ORIGINS` to your actual frontend domain (no wildcards in production).

### Issue: "Either GEMINI_API_KEY or RAG_BASE_URL must be set"
**Solution**: Set at least one:
- `GEMINI_API_KEY`: Get from https://ai.google.dev (recommended)
- `RAG_BASE_URL`: Your RAG service URL if deployed

### Issue: "SQLite database is not suitable for production"
**Solution**: Ensure you're using PostgreSQL, not SQLite. Check your `DATABASE_URL` starts with `postgresql://`.

### Issue: Deployment keeps failing
**Steps**:
1. Check the **Logs** tab for error messages
2. Verify all required environment variables are set
3. Check if Python version is >=3.12: Look for "python" in logs
4. Rebuild: Click **"Manual Deploy"** → **"Deploy latest commit"**

### Issue: Application crashes after deployment
**Steps**:
1. Check **Logs** for stack trace
2. Verify database connectivity: `DATABASE_URL` is correct
3. Verify `GEMINI_API_KEY` is valid
4. Try enabling `DEBUG=true` temporarily to see more logs
5. Check if dependencies installed correctly in logs

## Performance Tuning

### For Free Tier (recommended defaults):
- Workers: 4 (set in Procfile)
- Memory: Uses shared resources
- Suitable for: Testing, low-traffic development

### For Production (upgrade to Paid):
- Workers: 8-12 (modify Procfile)
- Memory: 512MB+ (Render Pro)
- Consider: Dedicated PostgreSQL tier
- Add: Redis caching for better performance

## Monitoring & Logging

### View Logs:
1. Service dashboard → **Logs** tab
2. Filter by time range or search keywords
3. Common log patterns:
   - `ERROR` - Application errors
   - `Database initialized` - Startup successful
   - `GET /health` - Health checks

### Enable Persistent Logs:
For better diagnostics, monitor:
- Slow queries: Set `DEBUG=true` temporarily
- Error rates: Check `/health` responses
- Database connections: Monitor in PostgreSQL dashboard

## Scaling & Upgrades

### As You Grow:

1. **Upgrade to Paid Plans**:
   - Get stable instance (not free tier)
   - Dedicated resources
   - Better uptime SLA

2. **Add Caching**:
   - Consider Redis instance
   - Cache exam templates, student profiles

3. **Add Monitoring**:
   - Set up error tracking (Sentry)
   - Add performance monitoring (New Relic, DataDog)

4. **Auto-scaling**:
   - Consider Kubernetes (more complex setup)
   - For now, vertical scaling (larger instances) is simpler

## API Endpoints

After deployment, your backend exposes:

```
GET  /health           - Health check (public)
GET  /ready            - Readiness check (for orchestrators)
POST /student/register - Register new student
GET  /student/{id}     - Get student profile
POST /exam/generate    - Generate exam
POST /exam/submit      - Submit exam answers
```

## Environment-Specific Behavior

### Development (ENVIRONMENT=development):
- Mock mode enabled by default
- CORS allows localhost
- Debug logging enabled
- SQLite supported

### Production (ENVIRONMENT=production):
- Mock mode disabled (requires real AI)
- CORS restricted to specific domains
- Debug logging disabled
- SQLite rejected (PostgreSQL required)
- All safety checks enabled

## Common Questions

**Q: Can I use free tier for production?**
A: Not recommended. Free tier instances restart weekly and resources are shared. Use for testing only.

**Q: How do I update the code after deployment?**
A: Push to your connected GitHub branch. Render automatically redeploys.

**Q: How do I rollback to a previous version?**
A: Use Render's **Deploy History** tab to redeploy a previous commit.

**Q: Can I use a different database than PostgreSQL?**
A: Not recommended. MySQL/MariaDB might work but aren't tested. Stick with PostgreSQL.

**Q: Do I need a RAG service?**
A: No, Gemini API works independently. RAG service is optional for enhanced generation.

## Support & Resources

- Render Documentation: https://render.com/docs
- FastAPI Documentation: https://fastapi.tiangolo.com
- Gemini API Setup: https://ai.google.dev
- PostgreSQL on Render: https://render.com/docs/databases

## Next Steps

1. ✅ Deploy backend on Render
2. 📱 Deploy frontend on Render (or Vercel)
3. 🔗 Connect frontend to backend API
4. 🧪 Run end-to-end tests
5. 📊 Set up monitoring and logging
6. 🚀 Go live!

---

**Need help?** Check Render's support or review the logs in your service dashboard.
