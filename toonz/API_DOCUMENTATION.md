# Toonz Animation API - Documentation

## Overview

Toonz Animation API is a production-ready REST API for automated 2D animation generation. Perfect for:

- **Content Creators**: Generate social media content at scale
- **E-learning Platforms**: Create educational explainer videos
- **Marketing Teams**: Produce product demos and advertisements
- **Developers**: Integrate animation into applications

## Features

- ✅ Audio-to-animation with automatic lip sync
- ✅ Multiple quality presets (Preview to 4K)
- ✅ Pre-built templates and character styles
- ✅ Batch processing
- ✅ Webhook notifications
- ✅ Usage tracking and billing
- ✅ RESTful API with OpenAPI docs
- ✅ Python SDK included

## Quick Start

### 1. Start the API Server

**Using Docker (Recommended):**
```bash
docker-compose up -d
```

**Using Python:**
```bash
pip install -r requirements-api.txt
uvicorn pipeline.api:app --reload
```

API will be available at: http://localhost:8000

### 2. Access API Documentation

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### 3. Create Your First Animation

```python
import requests

response = requests.post('http://localhost:8000/api/v1/renders',
    json={
        "audio_url": "https://example.com/narration.mp3",
        "template": "talking_head",
        "quality": "hd"
    },
    params={"user_id": "my_user"}
)

job = response.json()
print(f"Job ID: {job['job_id']}")
```

## API Endpoints

### Core Endpoints

#### `POST /api/v1/renders`
Create a new animation render job.

**Request:**
```json
{
  "audio_url": "https://example.com/audio.mp3",
  "transcript": "Optional text for better lip sync",
  "character_style": "simple",
  "template": "talking_head",
  "quality": "hd",
  "background_color": "#FFFFFF",
  "duration": 60.0,
  "webhook_url": "https://example.com/webhook"
}
```

**Response:**
```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "queued",
  "progress": 0.0,
  "created_at": "2024-01-15T10:30:00Z",
  "metadata": {
    "quality": "hd",
    "cost": 1.0
  }
}
```

#### `GET /api/v1/renders/{job_id}`
Get status of a render job.

**Response:**
```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "progress": 1.0,
  "created_at": "2024-01-15T10:30:00Z",
  "completed_at": "2024-01-15T10:35:00Z",
  "download_url": "/api/v1/renders/{job_id}/download"
}
```

**Status Values:**
- `queued`: Job is waiting to start
- `processing`: Job is being rendered
- `completed`: Job finished successfully
- `failed`: Job encountered an error

#### `GET /api/v1/renders/{job_id}/download`
Download completed animation.

Returns video file (MP4/WebM/GIF depending on request).

#### `DELETE /api/v1/renders/{job_id}`
Delete render job and output files.

### Batch Processing

#### `POST /api/v1/batch`
Create multiple render jobs at once.

**Request:**
```json
{
  "renders": [
    {
      "audio_url": "https://example.com/video1.mp3",
      "template": "explainer"
    },
    {
      "audio_url": "https://example.com/video2.mp3",
      "template": "product_demo"
    }
  ],
  "priority": 5
}
```

### Discovery Endpoints

#### `GET /api/v1/templates`
List available animation templates.

```json
{
  "templates": [
    {
      "id": "talking_head",
      "name": "Talking Head",
      "description": "Simple narration with character"
    },
    {
      "id": "explainer",
      "name": "Explainer",
      "description": "Educational content with animations"
    }
  ]
}
```

#### `GET /api/v1/characters`
List available character styles.

#### `GET /api/v1/pricing`
Get current pricing information.

### Usage & Billing

#### `GET /api/v1/usage/{user_id}`
Get usage statistics for billing.

```json
{
  "user_id": "my_user",
  "total_renders": 150,
  "total_duration": 4500.0,
  "total_cost": 125.50,
  "renders_this_month": 25,
  "renders_remaining": 75
}
```

## Parameters

### Quality Presets

| Quality | Resolution | FPS | Price |
|---------|-----------|-----|-------|
| `preview` | 640x360 | 24 | $0.10 |
| `standard` | 1280x720 | 30 | $0.50 |
| `hd` | 1920x1080 | 30 | $1.00 |
| `ultra` | 3840x2160 | 60 | $5.00 |

### Character Styles

- `simple`: Basic geometric shapes (fastest)
- `business`: Professional presenter
- `cartoon`: Fun animated character
- `realistic`: Human-like character

### Templates

- `talking_head`: Simple narration
- `explainer`: Educational content
- `product_demo`: Product showcase
- `social_media`: Short viral content
- `advertisement`: Commercial content

## Python SDK Usage

```python
from client_sdk import ToonzClient

# Initialize client
client = ToonzClient(
    api_key="your-api-key",
    base_url="https://api.toonz.example.com"
)

# Create animation
job = client.create_animation(
    audio_url="https://example.com/narration.mp3",
    transcript="Hello world!",
    template="explainer",
    quality="hd"
)

# Wait for completion
result = client.wait_for_completion(job.job_id, timeout=300)

# Download
client.download(job.job_id, "output/animation.mp4")

# Check usage
usage = client.get_usage()
print(f"Renders remaining: {usage['renders_remaining']}")
```

## Webhooks

Configure a webhook URL to receive notifications when renders complete:

```json
{
  "audio_url": "...",
  "webhook_url": "https://your-app.com/webhooks/toonz"
}
```

**Webhook Payload:**
```json
{
  "event": "render.completed",
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "download_url": "/api/v1/renders/{job_id}/download",
  "timestamp": "2024-01-15T10:35:00Z"
}
```

## Rate Limiting

Rate limits vary by subscription tier:

| Tier | Renders/Month | Max Duration |
|------|---------------|--------------|
| Free | 10 | 60s |
| Starter | 100 | 300s |
| Pro | 1,000 | 600s |
| Enterprise | Unlimited | Unlimited |

## Error Handling

All errors return standard HTTP status codes:

- `400 Bad Request`: Invalid parameters
- `401 Unauthorized`: Invalid API key
- `404 Not Found`: Job not found
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

**Error Response:**
```json
{
  "detail": "Render limit exceeded",
  "error_code": "RATE_LIMIT_EXCEEDED"
}
```

## Best Practices

### 1. Use Webhooks for Long Renders
Don't poll continuously. Configure webhooks for completion notifications.

### 2. Batch Similar Jobs
Use `/api/v1/batch` for multiple renders to improve efficiency.

### 3. Choose Appropriate Quality
Use `preview` for testing, `standard` for most content, `hd`/`ultra` for final production.

### 4. Provide Transcripts
Including transcripts improves lip sync accuracy.

### 5. Cache Results
Store job IDs and download URLs to avoid re-rendering identical content.

## Deployment

### Production Checklist

- [ ] Configure CORS for your domain
- [ ] Set up authentication (API keys)
- [ ] Configure external storage (S3/GCS)
- [ ] Set up monitoring (Sentry, Prometheus)
- [ ] Configure Redis for job queue
- [ ] Set up PostgreSQL for persistence
- [ ] Configure backup strategy
- [ ] Set up load balancing
- [ ] Configure rate limiting
- [ ] Set up SSL/TLS

### Environment Variables

```bash
# Required
REDIS_URL=redis://localhost:6379
DATABASE_URL=postgresql://user:pass@localhost/toonz

# Optional
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_BUCKET=toonz-renders
SENTRY_DSN=...
MAX_WORKERS=4
```

## Support

- **API Status**: Check `/health` endpoint
- **Documentation**: http://localhost:8000/docs
- **Issues**: GitHub Issues
- **Email**: support@toonz.example.com

## Roadmap

### Q1 2024
- [ ] Custom character upload
- [ ] Background music mixer
- [ ] Advanced templates
- [ ] Multi-language support

### Q2 2024
- [ ] Real-time rendering
- [ ] WebSocket progress updates
- [ ] Template marketplace
- [ ] Advanced analytics

## License

MIT License - See LICENSE file for details.
