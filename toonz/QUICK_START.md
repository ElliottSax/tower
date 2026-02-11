# Toonz Animation API - Quick Start

## 🚀 Deploy in 5 Minutes

### Option 1: Docker (Recommended)

```bash
cd /mnt/e/projects/toonz
docker-compose up -d
```

**Access**:
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- Health: http://localhost:8000/health

### Option 2: Local Development

```bash
cd /mnt/e/projects/toonz

# Install dependencies
pip install -r requirements-api.txt
pip install -r pipeline/requirements.txt

# Start server
uvicorn pipeline.api:app --reload --port 8000
```

## 💰 Revenue Model

| Quality | Resolution | Price/Render |
|---------|-----------|--------------|
| Preview | 640x360 | $0.10 |
| Standard | 1280x720 | $0.50 |
| HD | 1920x1080 | $1.00 |
| Ultra | 3840x2160 | $5.00 |

**Subscription Tiers**:
- Free: 10 renders/month
- Starter: 100 renders/month
- Pro: 1,000 renders/month
- Enterprise: Unlimited

## 📝 First API Call

```bash
curl -X POST "http://localhost:8000/api/v1/renders" \
  -H "Content-Type: application/json" \
  -d '{
    "audio_url": "https://example.com/audio.mp3",
    "template": "talking_head",
    "quality": "hd"
  }' \
  -G --data-urlencode "user_id=demo"
```

## 🐍 Python SDK

```python
from toonz.client_sdk import ToonzClient

client = ToonzClient(api_key="your-key")

# Create animation
job = client.create_animation(
    audio_url="https://example.com/audio.mp3",
    template="explainer",
    quality="hd"
)

# Wait and download
result = client.wait_for_completion(job.job_id)
client.download(job.job_id, "output.mp4")
```

## 🎯 Target Customers

1. **Content Creators** ($50-500/month)
   - YouTube/TikTok creators
   - Social media managers
   - Influencers

2. **E-Learning** ($500-5000/month)
   - Online course platforms
   - Educational institutions
   - Training companies

3. **Marketing Agencies** ($1000-10000/month)
   - Ad agencies
   - Digital marketing firms
   - Brand studios

4. **SaaS Integration** (Enterprise)
   - Video editing platforms
   - CMS providers
   - Automation tools

## 📊 Revenue Projections

**Conservative** (100 customers):
- 50 Free tier: $0
- 30 Starter ($50/mo): $1,500
- 15 Pro ($500/mo): $7,500
- 5 Enterprise ($2000/mo): $10,000
**Total: $19,000/month**

**Moderate** (500 customers):
- 250 Free: $0
- 150 Starter: $7,500
- 75 Pro: $37,500
- 25 Enterprise: $50,000
**Total: $95,000/month**

## 🔧 Next Steps

1. **Deploy to Cloud**
   - AWS ECS / GCP Cloud Run / Azure Container Apps
   - Configure domain + SSL
   - Set up CDN for video delivery

2. **Add Authentication**
   - API key generation
   - User management
   - OAuth integration

3. **Payment Processing**
   - Stripe integration
   - Subscription management
   - Usage metering

4. **Marketing**
   - Landing page
   - API playground
   - Example gallery
   - Documentation site

## 📚 Documentation

- **Full API Docs**: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- **Interactive Docs**: http://localhost:8000/docs
- **Client SDK**: [client-sdk.py](./client-sdk.py)

## 🧪 Testing

```bash
# Run pipeline tests (867 tests)
cd /mnt/e/projects/toonz
python3 -m pytest pipeline/tests/ -v

# Run API tests
python3 -m pytest tests/test_api.py -v

# Run system test
python3 -m pipeline.cli test
```

## 🎬 Example Templates

- `talking_head`: Simple narration with character
- `explainer`: Educational content with animations
- `product_demo`: Product showcase
- `social_media`: Short viral content (15-60s)
- `advertisement`: Commercial content

## 💡 Tips

1. **Start with Preview quality** for testing
2. **Use webhooks** instead of polling for long renders
3. **Batch similar jobs** for better efficiency
4. **Provide transcripts** for better lip sync
5. **Cache results** to avoid re-rendering

## 🆘 Support

- Health Check: `curl http://localhost:8000/health`
- View Logs: `docker-compose logs -f api`
- Stats: `curl http://localhost:8000/api/v1/admin/stats`

## 📈 Monitoring

Add to your deployment:
- Prometheus metrics
- Sentry error tracking
- Usage analytics
- Performance monitoring

---

**Ready to monetize?** Deploy today and start generating revenue from automated animation services!
