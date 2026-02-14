# Discovery Service Architecture

**Purpose:** Pure pattern/cycle detection engine. NO user-facing features.

---

## 🎯 **What This Service Does**

**ONLY THIS:**
1. Read politicians/trades from database
2. Run pattern detection algorithms
3. Find cycles, anomalies, correlations
4. Write discoveries back to database
5. Run 24/7 in background

**NOTHING ELSE:**
- No HTTP API for users
- No authentication
- No frontend
- No web scraping
- No CRUD operations

---

## 🏗️ **Clean Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    DISCOVERY SERVICE                        │
│                 (Pure Analysis Engine)                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Celery Workers (Background Jobs)                    │  │
│  │                                                        │  │
│  │  • scan_all_politicians()                            │  │
│  │  • find_cycles()                                     │  │
│  │  • detect_anomalies()                                │  │
│  │  • analyze_correlations()                            │  │
│  │  • run_experiments()                                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                        ↓                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Analysis Engines                                     │  │
│  │                                                        │  │
│  │  • FourierCyclicalDetector                           │  │
│  │  • RegimeDetector (HMM)                              │  │
│  │  • DynamicTimeWarpingMatcher                         │  │
│  │  • EnsemblePredictor                                 │  │
│  │  • CorrelationAnalyzer                               │  │
│  │  • ParameterSweepEngine                              │  │
│  └──────────────────────────────────────────────────────┘  │
│                        ↓                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Database Layer (via shared models)                  │  │
│  │                                                        │  │
│  │  READ:  Politician, Trade                            │  │
│  │  WRITE: PatternDiscovery, AnomalyDetection           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                        ↓
          ┌─────────────────────────┐
          │  Shared PostgreSQL DB   │
          │                         │
          │  Tables:                │
          │  • politicians (READ)   │
          │  • trades (READ)        │
          │  • pattern_discoveries  │
          │    (WRITE) ←──────────  │
          │  • anomaly_detections   │
          │    (WRITE) ←──────────  │
          └─────────────────────────┘
                        ↑
          ┌─────────────────────────┐
          │   Main Quant App        │
          │                         │
          │  • Reads discoveries    │
          │  • Shows to users       │
          │  • Writes trades        │
          └─────────────────────────┘
```

---

## 📁 **Minimal File Structure**

```
elliottsax/discovery/
├── discovery/
│   ├── core/
│   │   ├── config.py          # Settings
│   │   └── database.py        # DB connection
│   │
│   ├── ml/                    # Analysis algorithms
│   │   ├── cyclical/
│   │   │   ├── fourier.py     # Cycle detection
│   │   │   ├── hmm.py         # Regime analysis
│   │   │   └── dtw.py         # Pattern matching
│   │   ├── ensemble.py        # Multi-model
│   │   ├── correlation.py     # Network analysis
│   │   └── insights.py        # Automated insights
│   │
│   ├── engines/
│   │   ├── parameter_sweep.py # Parameter optimization
│   │   └── anomaly_hunter.py  # Anomaly detection
│   │
│   ├── tasks/
│   │   ├── celery_app.py      # Celery config
│   │   ├── discovery.py       # Pattern finding tasks
│   │   └── research.py        # Experimental models
│   │
│   └── utils/
│       └── llm_service.py     # AI descriptions
│
├── shared/                     # Symlink to quant-shared
│   └── models/                 # Database models
│
├── requirements.txt            # Dependencies
├── docker-compose.yml          # Deployment
└── README.md                   # Documentation
```

**What's NOT here:**
- ❌ No `api/` folder (no HTTP endpoints)
- ❌ No `auth/` folder (no authentication)
- ❌ No `scrapers/` folder (that's in main app)
- ❌ No `frontend/` (that's in main app)

---

## 🔄 **Data Flow**

### **Step 1: Main App Populates Data**
```
Main App:
1. Scrapes Congressional trades
2. Writes to `politicians` table
3. Writes to `trades` table
```

### **Step 2: Discovery Analyzes**
```
Discovery Service (2 AM daily):
1. SELECT * FROM politicians WHERE trade_count > 100
2. SELECT * FROM trades WHERE politician_id = ?
3. Run Fourier analysis → find 87-day cycle
4. INSERT INTO pattern_discoveries (...)
5. Run anomaly detection → find outliers
6. INSERT INTO anomaly_detections (...)
```

### **Step 3: Main App Shows Results**
```
Main App API:
1. SELECT * FROM pattern_discoveries WHERE strength > 0.8
2. Return to frontend
3. User sees: "87-day cycle found for Tuberville"
```

---

## ⚡ **Deployment**

### **Docker Compose**

```yaml
services:
  # Discovery workers (ONLY these)
  discovery-worker:
    build: .
    command: celery -A discovery.tasks.celery_app worker -Q discovery
    environment:
      - DATABASE_URL=${DATABASE_URL}  # Same DB as main app
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}

  # Scheduler
  celery-beat:
    build: .
    command: celery -A discovery.tasks.celery_app beat

  # NO web server!
  # NO API endpoints!
  # JUST workers!
```

### **Separation of Concerns**

```
Main App (elliottsax/quant):
- Port 8000: HTTP API
- Port 3000: Frontend
- Handles user requests
- Writes trades to DB

Discovery (elliottsax/discovery):
- NO ports exposed
- Only Celery workers
- Reads trades from DB
- Writes discoveries to DB
```

---

## 🎯 **Benefits of This Architecture**

### **1. Single Responsibility**
```
Discovery = "Find patterns"
Main App = "Show patterns to users"
```

### **2. Independent Scaling**
```
Main App: Scale for user traffic (1000 req/sec)
Discovery: Scale for CPU (4-8 cores)
```

### **3. Independent Deployment**
```
Discovery: Deploy new models without touching user app
Main App: Deploy UI changes without touching discovery
```

### **4. Fail Independently**
```
Discovery crashes? → Users still see old discoveries
Main App crashes? → Discovery keeps finding patterns
```

### **5. Simple to Understand**
```
Discovery: 10 files, pure analysis
Main App: User interface + database management
```

---

## 🔧 **What Gets Copied**

### **FROM quant/backend/app/ml/**
```bash
cp -r quant/backend/app/ml/cyclical/ discovery/ml/cyclical/
cp quant/backend/app/ml/ensemble.py discovery/ml/
cp quant/backend/app/ml/correlation.py discovery/ml/
cp quant/backend/app/ml/insights.py discovery/ml/
```

### **FROM quant-discovery/**
```bash
# Already created, just clean up:
discovery/
├── core/
├── tasks/
├── engines/
└── utils/
```

### **FROM quant-shared/**
```bash
# Symlink (don't copy)
ln -s ../../quant-shared shared
```

---

## 🚫 **What Does NOT Get Copied**

From main app:
- ❌ app/api/ (user endpoints)
- ❌ app/auth/ (authentication)
- ❌ app/scrapers/ (data ingestion)
- ❌ frontend/ (UI)
- ❌ app/models/ (database writes)

These stay in the main app!

---

## 📊 **Comparison**

| Feature | Main App | Discovery |
|---------|----------|-----------|
| HTTP API | ✅ Yes | ❌ No |
| Frontend | ✅ Yes | ❌ No |
| Auth | ✅ Yes | ❌ No |
| Scraping | ✅ Yes | ❌ No |
| Pattern Analysis | ❌ No | ✅ Yes |
| Celery Workers | ❌ No | ✅ Yes |
| Reads Trades | ✅ Yes | ✅ Yes |
| Writes Trades | ✅ Yes | ❌ No |
| Reads Discoveries | ✅ Yes | ❌ No |
| Writes Discoveries | ❌ No | ✅ Yes |

---

## ✅ **Implementation Checklist**

- [ ] Copy ML algorithms to discovery/
- [ ] Copy Celery tasks
- [ ] Copy LLM service
- [ ] Set up shared models (symlink)
- [ ] Configure database connection
- [ ] Remove all HTTP/API code
- [ ] Remove auth code
- [ ] Test pattern detection works
- [ ] Deploy workers
- [ ] Verify discoveries appear in main app

---

**Result:** A lean 500-line analysis engine that does ONE thing perfectly: find patterns.
