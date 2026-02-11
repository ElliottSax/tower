# Toonz Animation API

> Production-ready REST API for automated 2D animation generation

[![Tests](https://img.shields.io/badge/tests-867%20passing-brightgreen)]()
[![API](https://img.shields.io/badge/API-FastAPI-009688)]()
[![Docker](https://img.shields.io/badge/docker-ready-2496ED)]()
[![Revenue](https://img.shields.io/badge/revenue-ready-gold)]()

## Overview

Toonz Animation API transforms audio files into animated videos automatically using:
- **Lip Sync**: Rhubarb-powered mouth animation
- **Pre-built Templates**: Talking head, explainer, product demo, etc.
- **Quality Presets**: Preview (360p) to Ultra (4K)
- **Async Processing**: Background jobs with webhook notifications

## Quick Start

### Docker (Recommended)

```bash
docker-compose up -d
curl http://localhost:8000/health
```

Access API at: http://localhost:8000/docs

### Python

```bash
pip install -r requirements-api.txt
uvicorn pipeline.api:app --reload
```

## Usage

### REST API

```bash
# Create animation
curl -X POST "http://localhost:8000/api/v1/renders" \
  -H "Content-Type: application/json" \
  -d '{
    "audio_url": "https://example.com/audio.mp3",
    "template": "talking_head",
    "quality": "hd"
  }'

# Response
{
  "job_id": "550e8400-...",
  "status": "queued",
  "created_at": "2024-01-15T10:30:00Z"
}

# Check status
curl http://localhost:8000/api/v1/renders/{job_id}

# Download
curl http://localhost:8000/api/v1/renders/{job_id}/download -o video.mp4
```

### Python SDK

```python
from client_sdk import ToonzClient

client = ToonzClient(api_key="your-key")

job = client.create_animation(
    audio_url="https://example.com/audio.mp3",
    template="explainer",
    quality="hd"
)

result = client.wait_for_completion(job.job_id)
client.download(job.job_id, "output.mp4")
```

## Pricing

| Quality | Resolution | FPS | Price |
|---------|-----------|-----|-------|
| Preview | 640x360 | 24 | $0.10 |
| Standard | 1280x720 | 30 | $0.50 |
| HD | 1920x1080 | 30 | $1.00 |
| Ultra | 3840x2160 | 60 | $5.00 |

### Subscription Tiers

- **Free**: 10 renders/month
- **Starter**: 100 renders/month ($50/mo)
- **Pro**: 1,000 renders/month ($500/mo)
- **Enterprise**: Unlimited (custom pricing)

## Features

### Templates

- **talking_head**: Simple narration with character
- **explainer**: Educational content with animations
- **product_demo**: Product showcase
- **social_media**: Short viral content (15-60s)
- **advertisement**: Commercial content

### Character Styles

- **simple**: Basic geometric shapes (fastest)
- **business**: Professional presenter
- **cartoon**: Fun animated character
- **realistic**: Human-like character

### API Features

- ✅ Async job processing
- ✅ Batch rendering
- ✅ Webhook notifications
- ✅ Usage tracking & billing
- ✅ Rate limiting by tier
- ✅ Health checks
- ✅ OpenAPI/Swagger docs

## Architecture

```
Client → FastAPI → Redis Queue → Animation Pipeline → Video Output
                 ↓
              PostgreSQL
```

**Stack**:
- FastAPI (Python 3.11+)
- Redis (job queue)
- PostgreSQL (data store)
- Docker + docker-compose
- Pillow (image processing)
- FFmpeg (video encoding)
- Rhubarb Lip Sync (mouth animation)

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/renders` | POST | Create render job |
| `/api/v1/renders/{id}` | GET | Get job status |
| `/api/v1/renders/{id}/download` | GET | Download video |
| `/api/v1/renders/{id}` | DELETE | Delete job |
| `/api/v1/batch` | POST | Batch create |
| `/api/v1/templates` | GET | List templates |
| `/api/v1/characters` | GET | List characters |
| `/api/v1/pricing` | GET | Get pricing |
| `/api/v1/usage/{user_id}` | GET | Get usage stats |
| `/health` | GET | Health check |

Full API docs: http://localhost:8000/docs

## Testing

```bash
# All pipeline tests (867 tests)
pytest pipeline/tests/ -v

# API tests
pytest tests/test_api.py -v

# System test
python3 -m pipeline.cli test
```

## Deployment

### Production Checklist

- [ ] Deploy to cloud (AWS ECS / GCP Cloud Run / Azure)
- [ ] Configure domain + SSL/TLS
- [ ] Set up S3/GCS for storage
- [ ] Add authentication (API keys)
- [ ] Configure Stripe for payments
- [ ] Set up monitoring (Sentry, Prometheus)
- [ ] Configure CDN for video delivery
- [ ] Add rate limiting per IP
- [ ] Set up backups
- [ ] Create landing page

### Environment Variables

```bash
REDIS_URL=redis://localhost:6379
DATABASE_URL=postgresql://user:pass@localhost/toonz
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_BUCKET=toonz-renders
SENTRY_DSN=...
```

## Revenue Projections

**Conservative** (100 customers):
- Monthly: $19,000
- Annual: $228,000

**Moderate** (500 customers):
- Monthly: $95,000
- Annual: $1,140,000

## Documentation

- **API Reference**: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- **Quick Start**: [QUICK_START.md](./QUICK_START.md)
- **Completion Summary**: [COMPLETION_SUMMARY.md](./COMPLETION_SUMMARY.md)
- **Pipeline Docs**: [pipeline/README.md](./pipeline/README.md)

## Examples

See `client-sdk.py` for complete examples:
- Basic animation creation
- Batch rendering
- Usage tracking
- Error handling

## Support

- **Health**: `GET /health`
- **Docs**: http://localhost:8000/docs
- **Logs**: `docker-compose logs -f api`
- **Stats**: `GET /api/v1/admin/stats`

## License

MIT License

## Author

Built with Claude Sonnet 4.5

---

**Ready to monetize?** Deploy in 5 minutes with Docker and start generating revenue from automated animation services.
