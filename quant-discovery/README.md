# Quant Discovery Service

**Continuous pattern discovery and research engine for the Quant Analytics Platform**

## Overview

This is a **standalone background service** that continuously analyzes political trading data to discover:
- Hidden patterns and cycles
- Cross-politician correlations
- Anomalous trading behavior
- Novel predictive models
- Network dynamics

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  QUANT ANALYTICS ECOSYSTEM                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────┐      ┌──────────────────────┐   │
│  │   quant (main app)   │      │ quant-discovery      │   │
│  │                      │      │                      │   │
│  │ • User-facing API    │      │ • Background tasks   │   │
│  │ • Real-time queries  │      │ • Experiments        │   │
│  │ • Next.js frontend   │      │ • Pattern search     │   │
│  │                      │      │ • Model training     │   │
│  └──────────┬───────────┘      └──────────┬───────────┘   │
│             │                               │               │
│             │         ┌─────────────────────┘              │
│             │         │                                     │
│             ▼         ▼                                     │
│        ┌────────────────────┐                              │
│        │  Shared PostgreSQL │                              │
│        │                    │                              │
│        │ • politicians      │                              │
│        │ • trades           │                              │
│        │ • discoveries ←────┼─── Written by Discovery     │
│        │ • experiments      │                              │
│        │ • anomalies        │                              │
│        └────────────────────┘                              │
│                                                              │
│             ┌────────────────┐                              │
│             │ quant-shared   │                              │
│             │ (Python pkg)   │                              │
│             │                │                              │
│             │ • Models       │                              │
│             │ • Schemas      │                              │
│             │ • DB utils     │                              │
│             └────────────────┘                              │
│                     ▲                                        │
│                     │                                        │
│         ┌───────────┴──────────────┐                       │
│         │                           │                        │
│    Imported by              Imported by                     │
│    main app                 discovery                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

### 🔍 Pattern Discovery
- **Parameter Sweep**: Systematically tests all parameter combinations
- **Emergent Patterns**: Discovers patterns across the entire network
- **Cross-Market Analysis**: Correlates trading with market events

### 🧪 Model Experimentation
- **New Models**: Tests LSTM, ARIMA, Prophet, etc.
- **Hyperparameter Tuning**: Finds optimal configurations
- **A/B Testing**: Compares against production models

### ⚠️ Anomaly Hunting
- **Multi-Method Detection**: Statistical, model-based, network-based
- **Real-time Alerts**: Notifies on critical findings
- **Historical Analysis**: Finds past anomalies for investigation

### 🕸️ Network Analysis
- **Dynamic Clusters**: Detects emerging groups
- **Leading Indicators**: Finds predictive relationships
- **Coordination Detection**: Identifies synchronized trading

## Installation

### Prerequisites
- Python 3.11+
- PostgreSQL 15+ (shared with main app)
- Redis (for Celery)
- Docker & Docker Compose (optional)

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/elliottsax/discovery.git
cd discovery
```

2. **Install shared package**
```bash
cd ../quant-shared
pip install -e .
```

3. **Install discovery dependencies**
```bash
cd ../discovery
pip install -r requirements.txt
```

4. **Configure environment**
```bash
cp .env.example .env
# Edit .env with your database credentials (same as main app)
```

5. **Run database migrations**
```bash
# Creates discovery-specific tables in shared DB
alembic upgrade head
```

6. **Start workers**
```bash
# Start Celery workers
celery -A discovery.tasks.celery_app worker -Q discovery,research -c 5

# Start scheduler
celery -A discovery.tasks.celery_app beat
```

## Usage

### Running Discoveries

**Manual trigger:**
```bash
# Scan all politicians for patterns
python -m discovery.cli scan-all-politicians

# Run specific experiment
python -m discovery.cli experiment --model lstm --dataset all

# Hunt for anomalies
python -m discovery.cli hunt-anomalies --lookback 30
```

**Scheduled (automatic):**
- Discovery runs daily at 2 AM
- Network analysis every 6 hours
- Anomaly hunting every 4 hours
- Experiments weekly on Sunday

### Accessing Results

Results are stored in the shared database. The main app queries them:

```python
# Main app queries discoveries
from sqlalchemy import select
from shared.models import PatternDiscovery

# Get recent discoveries
discoveries = await db.execute(
    select(PatternDiscovery)
    .where(PatternDiscovery.strength > 0.85)
    .order_by(PatternDiscovery.discovery_date.desc())
    .limit(10)
)
```

Frontend displays them:
```typescript
// GET /api/v1/discoveries/recent
const discoveries = await api.discoveries.recent()
```

## Project Structure

```
quant-discovery/
├── discovery/
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py          # Settings
│   │   └── database.py        # DB connection to shared DB
│   │
│   ├── engines/
│   │   ├── __init__.py
│   │   ├── parameter_sweep.py # Systematic parameter testing
│   │   ├── emergent_patterns.py # Network-wide pattern discovery
│   │   ├── anomaly_hunter.py  # Multi-method anomaly detection
│   │   └── experiment_runner.py # New model experimentation
│   │
│   ├── tasks/
│   │   ├── __init__.py
│   │   ├── celery_app.py      # Celery configuration
│   │   ├── discovery_tasks.py # Background discovery jobs
│   │   └── research_tasks.py  # Experimental model tasks
│   │
│   ├── models/                # Discovery-specific models (if any)
│   │   └── __init__.py
│   │
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── mlflow_client.py   # MLFlow tracking
│   │   └── alerts.py          # Alert notifications
│   │
│   └── cli.py                 # Command-line interface
│
├── shared/                    # Shared package (symlink or git submodule)
│   └── → ../quant-shared/
│
├── tests/
│   ├── test_engines/
│   ├── test_tasks/
│   └── conftest.py
│
├── alembic/                   # Discovery-specific migrations
│   ├── versions/
│   └── env.py
│
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── .env.example
├── requirements.txt
├── pyproject.toml
├── alembic.ini
└── README.md
```

## Environment Variables

```bash
# Database (SHARED with main app)
DATABASE_URL=postgresql://user:pass@db:5432/quant

# Redis
REDIS_URL=redis://redis:6379/0

# MLFlow
MLFLOW_TRACKING_URI=http://mlflow:5000

# Discovery Settings
DISCOVERY_MODE=production  # or 'development'
ENABLE_ALERTS=true
ALERT_EMAIL=admin@example.com
ALERT_WEBHOOK=https://hooks.slack.com/...

# Resource Limits
MAX_WORKERS=5
WORKER_MEMORY_LIMIT=8GB
ENABLE_GPU=false
```

## Development

### Running Locally

```bash
# Install in development mode
pip install -e .
pip install -e ../quant-shared

# Run tests
pytest

# Run specific discovery
python -m discovery.cli scan-politician --id abc-123

# Monitor tasks
celery -A discovery.tasks.celery_app flower  # Web UI on :5555
```

### Adding New Discovery Engines

1. Create new engine in `discovery/engines/`
2. Add task in `discovery/tasks/discovery_tasks.py`
3. Schedule in `celery_app.py` if recurring
4. Write tests in `tests/test_engines/`

Example:
```python
# discovery/engines/my_engine.py
class MyDiscoveryEngine:
    def discover(self):
        # Your discovery logic
        return results

# discovery/tasks/discovery_tasks.py
@celery_app.task
def run_my_discovery():
    engine = MyDiscoveryEngine()
    results = engine.discover()
    store_discoveries(results)
    return results
```

## Deployment

### Docker Deployment

```bash
# Build image
docker build -t discovery:latest .

# Run with docker-compose
docker-compose up -d
```

### Production Deployment

```bash
# Deploy to Railway/Render/fly.io
railway up

# Or use Kubernetes
kubectl apply -f k8s/
```

### Monitoring

- **Celery Flower**: Monitor tasks at `http://localhost:5555`
- **MLFlow**: View experiments at `http://localhost:5000`
- **Logs**: `docker-compose logs -f discovery`

## Integration with Main App

### Data Flow

```
Discovery Service              Shared Database              Main App
───────────────────            ─────────────────            ─────────

1. Celery task runs
2. Analyzes patterns
3. Writes discoveries ──────►  pattern_discoveries   ◄──── 4. API queries
                               anomaly_detections          5. Returns to user
   MLFlow tracks ──────────►   model_experiments
   experiments
```

### API Endpoints (Main App)

The main app exposes these endpoints that read discovery results:

- `GET /api/v1/discoveries/recent` - Latest discoveries
- `GET /api/v1/discoveries/politician/{id}` - Politician-specific
- `GET /api/v1/anomalies/critical` - High-severity anomalies
- `GET /api/v1/experiments/results` - Model experiment results

### Alerts & Notifications

When critical discoveries are made:
1. Discovery service stores in DB
2. Sends alert via webhook/email
3. Main app displays notification banner
4. Premium users get real-time push notification

## Performance

### Resource Usage

**Typical:**
- CPU: 2-4 cores
- RAM: 4-8 GB
- Disk: 10 GB (logs, temp files)

**Heavy experiments:**
- CPU: 8+ cores (or GPU)
- RAM: 16-32 GB
- Disk: 50 GB (model checkpoints)

### Optimization

- Use parameter sampling instead of full grid search
- Cache intermediate results in Redis
- Run experiments on separate GPU worker
- Limit concurrent tasks: `worker_prefetch_multiplier=1`

## Troubleshooting

### Common Issues

**Database connection errors:**
```bash
# Check main app DB is accessible
psql $DATABASE_URL -c "SELECT 1"

# Verify credentials match main app
cat ../quant/.env | grep DATABASE_URL
```

**Tasks not running:**
```bash
# Check Celery workers
celery -A discovery.tasks.celery_app inspect active

# Check scheduled tasks
celery -A discovery.tasks.celery_app inspect scheduled

# Restart beat
docker-compose restart celery-beat
```

**Out of memory:**
```bash
# Reduce concurrent workers
celery worker -c 2  # Instead of -c 5

# Increase memory limit
docker-compose up -d --scale discovery=1 --memory=8g
```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-discovery`)
3. Commit changes (`git commit -m 'Add amazing discovery'`)
4. Push to branch (`git push origin feature/amazing-discovery`)
5. Open Pull Request

## License

MIT License - see LICENSE file

## Related Projects

- **[quant](https://github.com/elliottsax/quant)** - Main application
- **[quant-shared](https://github.com/elliottsax/quant-shared)** - Shared models package

## Support

- **Issues**: https://github.com/elliottsax/discovery/issues
- **Discussions**: https://github.com/elliottsax/discovery/discussions
- **Email**: support@quantanalytics.com

---

**Status**: 🚧 Active Development

**Deployed**: https://discovery.quantanalytics.com (internal)

**Last Updated**: 2025-11-15
