# Quant Shared Package

**Shared models, schemas, and utilities for Quant Analytics ecosystem**

This package contains code shared between:
- `quant` - Main web application
- `quant-discovery` - Background discovery service

## Installation

```bash
# Install in development mode
pip install -e .

# Install from git
pip install git+https://github.com/elliottsax/quant-shared.git
```

## Usage

```python
# In main app
from quant_shared.models import Politician, Trade, PatternDiscovery
from quant_shared.schemas import PoliticianSchema, TradeSchema
from quant_shared.utils import get_db_session

# In discovery service
from quant_shared.models import PatternDiscovery
from quant_shared.utils import store_discovery

# Create a discovery
discovery = PatternDiscovery(
    politician_id=pol_id,
    pattern_type='cycle',
    strength=0.87,
    confidence=0.92,
    parameters={'window': 30, 'threshold': 0.8}
)
session.add(discovery)
session.commit()
```

## Contents

### Models (`quant_shared.models`)
- `Politician` - Politician database model
- `Trade` - Trade database model
- `PatternDiscovery` - Discovered patterns (written by discovery service)
- `AnomalyDetection` - Detected anomalies
- `ModelExperiment` - Experiment results
- `NetworkDiscovery` - Network findings

### Schemas (`quant_shared.schemas`)
- Pydantic schemas for API serialization
- Matches database models

### Utils (`quant_shared.utils`)
- Database connection helpers
- Common utilities

## Development

```bash
# Run tests
pytest

# Type checking
mypy quant_shared

# Linting
ruff check quant_shared
```

## Versioning

We use semantic versioning. When making changes:
- **Major**: Breaking changes (change model fields)
- **Minor**: New features (add new models)
- **Patch**: Bug fixes

Both apps should pin to compatible versions:
```
quant_shared>=1.0.0,<2.0.0
```
