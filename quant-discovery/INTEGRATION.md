# Integration Guide: Discovery Service ↔ Main App

This document explains how the discovery service integrates with the main Quant Analytics application.

## Architecture Overview

```
┌────────────────────────────────────────────────────────────┐
│                     INTEGRATION FLOW                       │
└────────────────────────────────────────────────────────────┘

┌──────────────────────┐              ┌─────────────────────┐
│   Main App (quant)   │              │ Discovery Service   │
│                      │              │                     │
│ • FastAPI server     │              │ • Celery workers    │
│ • Next.js frontend   │              │ • Background tasks  │
│ • User requests      │              │ • Experiments       │
└──────────┬───────────┘              └──────────┬──────────┘
           │                                     │
           │  1. Shares same PostgreSQL DB      │
           │     ┌─────────────────────┐       │
           └─────►   PostgreSQL DB     ◄───────┘
                 │                     │
                 │ • politicians       │
                 │ • trades            │
                 │ • pattern_discoveries ← Written by Discovery
                 │ • anomaly_detections  ← Written by Discovery
                 │ • model_experiments   ← Written by Discovery
                 └─────────────────────┘

           2. Main app READS discoveries, Discovery WRITES them
```

## Data Flow

### 1. Discovery Service → Database

**Discovery service performs analysis and writes results:**

```python
# discovery/tasks/discovery_tasks.py

from quant_shared.models import PatternDiscovery

# Discover a pattern
discovery = PatternDiscovery(
    politician_id=politician.id,
    pattern_type='fourier_cycle',
    strength=0.92,
    confidence=0.87,
    parameters={'window': 30, 'threshold': 0.8},
    description="Strong 90-day cycle detected"
)
db.add(discovery)
db.commit()
```

### 2. Main App ← Database

**Main app queries discoveries for users:**

```python
# quant/backend/app/api/v1/discoveries.py

from quant_shared.models import PatternDiscovery

@router.get("/discoveries/recent")
async def get_recent_discoveries(db: AsyncSession = Depends(get_db)):
    """Get recent pattern discoveries."""

    stmt = (
        select(PatternDiscovery)
        .where(PatternDiscovery.strength > 0.85)
        .order_by(PatternDiscovery.discovery_date.desc())
        .limit(10)
    )

    discoveries = await db.execute(stmt)
    return discoveries.scalars().all()
```

### 3. Frontend ← API

**Frontend displays discoveries to users:**

```typescript
// quant/frontend/src/app/discoveries/page.tsx

const DiscoveriesPage = () => {
  const { data: discoveries } = useDiscoveries()

  return (
    <div>
      {discoveries.map(d => (
        <DiscoveryCard
          type={d.pattern_type}
          strength={d.strength}
          politician={d.politician_name}
          description={d.description}
        />
      ))}
    </div>
  )
}
```

## Shared Models

Both services import from `quant-shared` package:

```python
# Both services use the same models
from quant_shared.models import (
    Politician,      # Read by both
    Trade,           # Read by both
    PatternDiscovery, # Written by Discovery, read by Main
    AnomalyDetection, # Written by Discovery, read by Main
)
```

## Database Schema

### Existing Tables (created by main app)
- `politicians` - Main app creates, both read
- `trades` - Main app creates, both read

### New Tables (created by discovery service)
- `pattern_discoveries` - Discovery creates, main reads
- `anomaly_detections` - Discovery creates, main reads
- `model_experiments` - Discovery creates, main reads
- `network_discoveries` - Discovery creates, main reads

## API Endpoints (Main App)

Add these endpoints to the main app to expose discoveries:

```python
# quant/backend/app/api/v1/discoveries.py

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from quant_shared.models import PatternDiscovery, AnomalyDetection

router = APIRouter()

@router.get("/discoveries/recent")
async def get_recent_discoveries(
    limit: int = 10,
    db: AsyncSession = Depends(get_db)
):
    """Get recent pattern discoveries."""
    stmt = (
        select(PatternDiscovery)
        .join(Politician)
        .order_by(PatternDiscovery.discovery_date.desc())
        .limit(limit)
    )
    results = await db.execute(stmt)
    return results.scalars().all()

@router.get("/anomalies/critical")
async def get_critical_anomalies(
    severity_threshold: float = 0.8,
    db: AsyncSession = Depends(get_db)
):
    """Get critical anomalies requiring investigation."""
    stmt = (
        select(AnomalyDetection)
        .join(Politician)
        .where(AnomalyDetection.severity >= severity_threshold)
        .where(AnomalyDetection.investigated == False)
        .order_by(AnomalyDetection.severity.desc())
    )
    results = await db.execute(stmt)
    return results.scalars().all()

@router.get("/discoveries/politician/{politician_id}")
async def get_politician_discoveries(
    politician_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get all discoveries for a specific politician."""
    stmt = (
        select(PatternDiscovery)
        .where(PatternDiscovery.politician_id == politician_id)
        .order_by(PatternDiscovery.strength.desc())
    )
    results = await db.execute(stmt)
    return results.scalars().all()
```

## Deployment Configuration

### Option 1: Same Host

If running on the same server:

```yaml
# docker-compose.yml (combined)

services:
  # Main app
  api:
    ...
    environment:
      - DATABASE_URL=postgresql://...
      - REDIS_URL=redis://redis:6379/0

  # Discovery service
  discovery-worker:
    ...
    environment:
      - DATABASE_URL=postgresql://...  # SAME DATABASE
      - REDIS_URL=redis://redis:6379/0  # SAME REDIS

  # Shared services
  postgres:
    image: timescale/timescaledb:latest-pg15

  redis:
    image: redis:7-alpine
```

### Option 2: Separate Hosts

If running on different servers:

**Main App (server 1):**
```env
DATABASE_URL=postgresql://db.example.com:5432/quant
REDIS_URL=redis://redis.example.com:6379/0
```

**Discovery Service (server 2):**
```env
DATABASE_URL=postgresql://db.example.com:5432/quant  # SAME DB
REDIS_URL=redis://redis.example.com:6379/1  # Can be different Redis DB
```

## Migration Strategy

### Step 1: Install Shared Package in Main App

```bash
cd /mnt/e/projects/quant/quant/backend

# Add to requirements.txt
echo "-e ../../quant-shared" >> requirements.txt

# Install
pip install -e ../../quant-shared
```

### Step 2: Update Main App Imports

```python
# OLD (main app)
from app.models.politician import Politician
from app.models.trade import Trade

# NEW (using shared package)
from quant_shared.models import Politician, Trade
```

### Step 3: Run Discovery Migrations

```bash
cd /mnt/e/projects/quant-discovery

# Create discovery tables
alembic upgrade head
```

This creates:
- `pattern_discoveries`
- `anomaly_detections`
- `model_experiments`
- `network_discoveries`

### Step 4: Start Discovery Service

```bash
# Start workers
docker-compose up -d

# Monitor
docker-compose logs -f discovery-worker
```

### Step 5: Add API Endpoints to Main App

Create `quant/backend/app/api/v1/discoveries.py` with the endpoints above.

## Monitoring

### Discovery Service Metrics

```bash
# Celery Flower UI
open http://localhost:5555

# Check running tasks
celery -A discovery.tasks.celery_app inspect active

# Check scheduled tasks
celery -A discovery.tasks.celery_app inspect scheduled
```

### Database Queries

```sql
-- Check recent discoveries
SELECT * FROM pattern_discoveries
ORDER BY discovery_date DESC
LIMIT 10;

-- Check critical anomalies
SELECT * FROM anomaly_detections
WHERE severity > 0.8
AND investigated = false
ORDER BY severity DESC;

-- Check experiment results
SELECT model_name, deployment_ready, experiment_date
FROM model_experiments
ORDER BY experiment_date DESC;
```

## Troubleshooting

### Issue: Discovery can't connect to database

**Solution:** Ensure `DATABASE_URL` matches main app exactly:

```bash
# In main app
echo $DATABASE_URL

# In discovery service (should be identical)
echo $DATABASE_URL
```

### Issue: Models not found

**Solution:** Ensure shared package is installed:

```bash
pip install -e ../quant-shared
```

### Issue: Discoveries not appearing in main app

**Solution:** Check if main app is querying correctly:

```python
from quant_shared.models import PatternDiscovery
from sqlalchemy import select

stmt = select(PatternDiscovery).limit(5)
results = db.execute(stmt)
print(list(results.scalars()))  # Should show discoveries
```

## Performance Considerations

### Database Load

- Discovery runs **heavy queries** (scanning all politicians)
- Recommended: Use read replica if available
- Or schedule discoveries during off-peak hours (2-4 AM)

### Redis Usage

- Discovery uses Redis for task queue
- Can share with main app or use separate Redis instance
- Monitor memory usage: `redis-cli INFO memory`

### Resource Allocation

**Discovery Workers:**
- CPU: 4 cores per worker
- RAM: 8 GB per worker
- Disk: 10 GB for logs/cache

**Research Workers:**
- CPU: 8 cores (or GPU)
- RAM: 16 GB
- Disk: 50 GB for model checkpoints

## Security

### Database Access

Discovery service needs:
- ✅ READ access to `politicians`, `trades`
- ✅ WRITE access to `pattern_discoveries`, `anomaly_detections`, etc.
- ❌ Should NOT write to `politicians` or `trades`

### API Keys

If main app requires auth, discovery doesn't need API keys.
It accesses database directly.

## Next Steps

1. **Test Integration:**
   ```bash
   # Run discovery manually
   python -m discovery.cli scan-politician --id <politician-uuid>

   # Check results in main app
   curl http://localhost:8000/api/v1/discoveries/recent
   ```

2. **Add Frontend Components:**
   Create `quant/frontend/src/app/discoveries/page.tsx`

3. **Set Up Alerts:**
   Configure webhooks for critical anomalies

4. **Monitor Performance:**
   Track discovery job duration, success rate

---

**Last Updated:** 2025-11-15
**Status:** ✅ Ready for Integration
