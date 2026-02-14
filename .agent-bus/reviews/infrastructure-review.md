# Infrastructure Code Review

**Reviewer**: Senior Code Reviewer (Security + DevOps Focus)
**Date**: 2026-02-11
**Scope**: ~60 source files across 3 projects
**Method**: Full source file read of all .py, .cs, Dockerfile, docker-compose.yml, config files

---

## Project 1: Acquisition System

**Path**: `/mnt/e/projects/acquisition-system/`
**Stack**: Python 3.11+, FastAPI, PostgreSQL, Docker, Next.js 15
**Size**: ~42,000 LOC (37 Python backend files, ~7,500 LOC backend + tests + dashboard)

### Critical Issues

**CRIT-1: No API Authentication -- All Endpoints Publicly Accessible**
- **File**: `/mnt/e/projects/acquisition-system/backend/api/app.py` (entire file)
- **Impact**: SEVERE -- full data exfiltration, unauthorized pipeline execution
- The FastAPI application has zero authentication middleware. No JWT, no API keys, no OAuth2, no session tokens. Every endpoint is open:
  - `GET /api/leads` -- exposes PII (names, emails, ages, retirement scores)
  - `POST /api/pipeline/run/{job_type}` -- anyone can trigger scraping/enrichment jobs that consume API credits
  - `POST /api/campaigns` -- anyone can create and start email campaigns
  - `PATCH /api/deals/{id}/stage` -- anyone can manipulate the deal pipeline
  - `GET /api/leads/hot` -- exposes highest-value leads

**CRIT-2: Webhook Endpoints Have No Signature Verification**
- **File**: `/mnt/e/projects/acquisition-system/backend/api/routes/webhooks.py:1-4, 18-44`
- **Impact**: HIGH -- attackers can inject fake email events, corrupt campaign metrics
- Lines 3-4 import `hmac` and `hashlib` but never use them. The webhook endpoints at lines 18 (`/instantly`), 47 (`/smartlead`), and 85 (`/email-reply`) accept any POST request without verifying origin.
- An attacker could POST fake "replied" events to trigger notification spam, or fake "bounced" events to mark legitimate contacts as bounced.

**CRIT-3: Webhook and Pipeline Endpoints Return Error Details to Clients**
- **File**: `/mnt/e/projects/acquisition-system/backend/api/routes/webhooks.py:44, 82, 175`
- **File**: `/mnt/e/projects/acquisition-system/backend/api/routes/pipeline.py:43`
- `webhooks.py` line 44: `return {"status": "error", "message": str(e)}` -- leaks internal exception messages (stack traces, database errors, file paths) to callers.
- `pipeline.py` line 43: `return {"error": f"Invalid job type..."}` -- returns HTTP 200 with error body instead of raising `HTTPException(status_code=400)`. This means error monitoring tools will not detect these as errors.

**CRIT-4: Docker Container Runs as Root**
- **File**: `/mnt/e/projects/acquisition-system/Dockerfile` (entire file, 41 lines)
- **Impact**: HIGH -- container escape exploits gain root privileges
- No `USER` directive anywhere in the Dockerfile. All three stages (base, scraper, api) run as root. If any code execution vulnerability is exploited (e.g., via Playwright browser, pickle deserialization), the attacker has root access inside the container.
- Fix: Add `RUN addgroup --system appuser && adduser --system --ingroup appuser appuser` and `USER appuser` before the `CMD`.

**CRIT-5: Database Password Defaults to "devpassword" in Docker Compose**
- **File**: `/mnt/e/projects/acquisition-system/docker-compose.yml:7, 26, 40, 69, 86`
- `POSTGRES_PASSWORD: ${DB_PASSWORD:-devpassword}` -- if the `DB_PASSWORD` environment variable is not set, all services use the hardcoded default `devpassword`. This password appears in 5 different service definitions. Combined with port 5432 being exposed on the host (line 9: `"5432:5432"`), the database is accessible with a known password from outside the container.

**CRIT-6: Pickle Deserialization Enables Arbitrary Code Execution**
- **File**: `/mnt/e/projects/acquisition-system/backend/models/retirement_scorer.py:353-354`
- ```python
  with open(path, 'rb') as f:
      model_data = pickle.load(f)
  ```
- `pickle.load()` can execute arbitrary Python code embedded in a malicious pickle file. If an attacker can write to the model file path (via a file upload vulnerability, compromised CI/CD, or shared filesystem), they achieve full remote code execution. Use `joblib` with `safe_load` or serialize to a safe format (JSON, ONNX).

**CRIT-7: Settings Module Crashes at Import Time**
- **File**: `/mnt/e/projects/acquisition-system/backend/utils/config.py:152`
- ```python
  settings = Settings()
  ```
- `Settings()` is instantiated at module import time. `DATABASE_URL` and `ANTHROPIC_API_KEY` are required fields (`Field(...)`). If they are not set, importing ANY module that transitively imports `config.py` will crash with a `ValidationError`. This makes:
  - Unit tests impossible to run without a fully configured `.env`
  - Docker builds that import backend modules will fail
  - No graceful degradation or error message about missing config

### Warnings

**WARN-1: Source Code Volume Mount in Docker Compose**
- **File**: `/mnt/e/projects/acquisition-system/docker-compose.yml:51`
- `./backend:/app/backend` mounts source code into the container. This is a development convenience that should never exist in production. Changes to local files immediately affect the running container, bypassing build/test processes. The `./data:/app/data` mount is acceptable.

**WARN-2: No Rate Limiting on Any API Endpoint**
- **File**: `/mnt/e/projects/acquisition-system/backend/api/app.py`
- No `slowapi` or similar rate limiting middleware. The pipeline trigger endpoints could be abused to spam API credits (Claude, email enrichment providers). The lead listing endpoints could be used for bulk data scraping.

**WARN-3: Dependencies Pinned to 2024 Versions (2+ Years Old)**
- **File**: `/mnt/e/projects/acquisition-system/backend/requirements.txt`
- `anthropic==0.18.1` (current ~0.40+, major API changes), `sqlalchemy==2.0.25` (security patches since), `requests==2.31.0` (known CVEs), `sentry-sdk==1.40.0` (major version 2.x), `playwright==1.41.2` (security updates), `pydantic==2.5.3` (bug fixes). No lock file exists.

**WARN-4: Double Commit in Deal Advancement (Non-Atomic)**
- **File**: `/mnt/e/projects/acquisition-system/backend/api/routes/deals.py:127, 137`
- The `advance_deal` endpoint calls `db.commit()` twice: once for the deal stage update (line 127) and once for the activity log insert (line 137). If the second commit fails, the deal stage is updated but the activity log is lost, creating an inconsistent audit trail. Should be a single transaction.

**WARN-5: Webhook Routes Use Manual DB Session Instead of FastAPI Depends**
- **File**: `/mnt/e/projects/acquisition-system/backend/api/routes/webhooks.py:33-38, 71-76, 99-171`
- All three webhook handlers use `db = next(get_db())` with manual `try/finally/db.close()` instead of FastAPI's `Depends(get_db)` pattern. This means no automatic session cleanup on unhandled exceptions and inconsistent behavior with other routes.

**WARN-6: FastAPI Deps get_db Never Commits**
- **File**: `/mnt/e/projects/acquisition-system/backend/api/deps.py:9-15`
- The FastAPI dependency `get_db` only calls `db.close()`, never `db.commit()`. Compare with `database.py:30-47` which auto-commits. Routes like `campaigns.py:63` must manually call `db.commit()`. If a developer forgets, changes are silently lost with no error.

**WARN-7: env_file and environment Both Set (Precedence Confusion)**
- **File**: `/mnt/e/projects/acquisition-system/docker-compose.yml:44-46`
- Services have both `environment:` and `env_file:` directives. The `.env` file may override the explicit Docker-specific `DATABASE_URL` (which points to the `db` service hostname). The precedence rules are subtle and can cause the API to connect to the wrong database.

**WARN-8: Sentry Re-Initialized on Every setup_logging() Call**
- **File**: `/mnt/e/projects/acquisition-system/backend/utils/logging.py:66-78`
- `sentry_sdk.init()` is called every time `setup_logging()` is invoked. Since `setup_logging()` is called at module import time in every route file (e.g., `webhooks.py:13`, `pipeline.py:11`, `leads.py:11`), Sentry is initialized multiple times. While Sentry handles this gracefully, it's wasteful and could cause issues with different configurations.

**WARN-9: f-string Column Name Interpolation in SQL**
- **File**: `/mnt/e/projects/acquisition-system/backend/api/routes/webhooks.py:203, 215-216`
- ```python
  db.execute(text(f"UPDATE touches SET {timestamp_field} = NOW()..."))
  db.execute(text(f"UPDATE campaigns SET {counter} = {counter} + 1..."))
  ```
- While `timestamp_field` and `counter` come from a hardcoded dict (not user input), this pattern of f-string interpolation in SQL is dangerous and could easily become a vulnerability if a developer adds user input to the dict. The parameterized values are correct, but column names should be validated against an allowlist.

**WARN-10: Health Check Does Not Verify Database Connectivity**
- **File**: `/mnt/e/projects/acquisition-system/backend/api/app.py:41-43`
- ```python
  @app.get("/api/health")
  def health():
      return {"status": "ok", "version": "0.1.0"}
  ```
- Always returns "ok" without checking database connectivity. The Docker healthcheck relies on this endpoint, so the API could report healthy while the database is down.

### Code Quality: 6/10

### Summary

The Acquisition System has a solid architectural foundation with clean separation of concerns (scrapers, enrichment, models, outreach, orchestration), good Docker multi-stage builds, parameterized SQL throughout, and proper Pydantic configuration management. However, it has severe security gaps that make it unsuitable for production deployment: no API authentication, no webhook verification, containers running as root, default database passwords, and pickle deserialization vulnerabilities. The dependency versions are 2+ years old with known CVEs. The codebase needs a security hardening pass before any public-facing deployment.

**Positives**: Good Docker multi-stage builds reducing attack surface (Playwright not in API image). Comprehensive `.gitignore` and `.dockerignore`. Parameterized SQL everywhere. Pydantic Settings for type-safe configuration. Database health checks in Docker Compose with `service_healthy` conditions. Sentry integration for error tracking. Clean module boundaries.

---

## Project 2: ContractIQ

**Path**: `/mnt/e/projects/contractiq/`
**Stack**: Python 3.8+, LangChain, FAISS, Streamlit, FastAPI
**Size**: ~4,500 LOC

### Critical Issues

**CRIT-1: Dangerous FAISS Deserialization**
- **File**: `/mnt/e/projects/contractiq/src/rag_pipeline.py:276-280`
- ```python
  self.vectorstore = FAISS.load_local(
      str(load_path),
      self.embeddings,
      allow_dangerous_deserialization=True
  )
  ```
- `allow_dangerous_deserialization=True` enables pickle deserialization of the FAISS index. If an attacker can replace the vector store file on disk, they achieve arbitrary code execution. This flag exists specifically because FAISS indexes use pickle, which is inherently insecure. The comment in the codebase does not acknowledge this risk.

**CRIT-2: CORS Wildcard with Credentials Enabled**
- **File**: `/mnt/e/projects/contractiq/api/main.py:81-87`
- ```python
  app.add_middleware(
      CORSMiddleware,
      allow_origins=["*"],
      allow_credentials=True,
      allow_methods=["*"],
      allow_headers=["*"],
  )
  ```
- `allow_origins=["*"]` combined with `allow_credentials=True` is a dangerous combination. While most browsers will block credential-bearing requests when the origin is `*`, some older browsers and non-browser clients will not. This exposes the healthcare contract API to cross-origin attacks. This handles PHI (Protected Health Information) -- healthcare contract data -- which has HIPAA compliance implications.

**CRIT-3: No Authentication on Any Endpoint (Healthcare Data)**
- **File**: `/mnt/e/projects/contractiq/api/main.py` (entire file)
- **File**: `/mnt/e/projects/contractiq/app.py` (entire file)
- Neither the FastAPI API nor the Streamlit web interface has any authentication. Healthcare contract data (rates, payment terms, payer information) is accessible to anyone who can reach the port. Given this is healthcare data, this may constitute a HIPAA violation depending on the deployment context.

### Warnings

**WARN-1: Global Mutable State for Analyzer**
- **File**: `/mnt/e/projects/contractiq/api/main.py:38`
- ```python
  analyzer: ContractAnalyzer = None
  ```
- The analyzer is a module-level global variable shared across all requests. If the analyzer has mutable state (and it does -- it maintains a vectorstore), concurrent requests could interfere with each other, causing race conditions or data corruption.

**WARN-2: Error Details Exposed to Clients**
- **File**: `/mnt/e/projects/contractiq/api/main.py:134` (and multiple other endpoints)
- ```python
  raise HTTPException(status_code=500, detail=str(e))
  ```
- Internal exception messages are returned to the client. These may contain file paths, database connection strings, or API key fragments.

**WARN-3: Docker Compose Uses Deprecated Version Key**
- **File**: `/mnt/e/projects/contractiq/docker-compose.yml:1`
- `version: '3.8'` is deprecated in modern Docker Compose. While still functional, it should be removed.

**WARN-4: Duplicate Method Definition**
- **File**: `/mnt/e/projects/contractiq/src/contract_analyzer.py:430 and 635`
- `generate_negotiation_report` is defined twice with different signatures. The second definition (line 635) silently overwrites the first (line 430). The first version is dead code that will never execute.

**WARN-5: Fragile Import Pattern**
- **File**: `/mnt/e/projects/contractiq/src/contract_analyzer.py:15`
- ```python
  from rag_pipeline import HealthcareContractRAG
  ```
- This bare import only works if the CWD is `src/` or `src/` is on `sys.path`. The `cli.py` and `app.py` manually add `src` to `sys.path`. This will break with any import restructuring, IDE refactoring, or pytest discovery.

**WARN-6: Dependencies Use Wide Range Specifiers Without Lock File**
- **File**: `/mnt/e/projects/contractiq/requirements.txt`
- Ranges like `langchain>=0.3.0,<0.4.0` allow different dependency trees on different installs. No `requirements.lock` or `pip freeze` output exists. Builds are not reproducible.

**WARN-7: No Dockerfile USER Directive**
- **File**: `/mnt/e/projects/contractiq/Dockerfile`
- Multi-stage build (base/dependencies/application/development) but never creates or switches to a non-root user.

### Code Quality: 4/10

### Summary

ContractIQ is an early-stage project with a functional RAG pipeline and multi-provider LLM support (Claude/Gemini/OpenAI). The code organization is reasonable with separate modules for the RAG pipeline and contract analysis. However, it has significant production readiness gaps: no authentication on healthcare data (potential HIPAA concern), dangerous FAISS deserialization, CORS wildcard with credentials, duplicate method definitions, fragile import patterns, and no reproducible dependency management. The Streamlit interface has XSRF protection enabled, which is good. The project needs a substantial security and quality pass before handling real healthcare contract data.

**Positives**: Clean `.env.example` with no real credentials. XSRF protection enabled in Streamlit config. Privacy-respecting `gatherUsageStats = false`. Multi-provider LLM abstraction is well done. Good error handling in RAG pipeline methods.

---

## Project 3: MobileGameCore

**Path**: `/mnt/e/projects/MobileGameCore/`
**Stack**: Unity C# (2021.3+), Firebase, Unity IAP, Unity Ads, Unity Cloud Save
**Size**: ~6,500 LOC (17 core systems)

### Critical Issues

**CRIT-1: IAP Manager Has No Server-Side Receipt Validation**
- **File**: `/mnt/e/projects/MobileGameCore/Runtime/Monetization/IAPManager.cs`
- The IAP purchase flow grants items/currency immediately on the client side after `ProcessPurchase` returns `PurchaseProcessingResult.Complete`. There is no server-side receipt validation. This means:
  - On Android, modified APKs can inject fake purchase confirmations
  - On iOS, jailbroken devices can use fake StoreKit servers
  - Receipt validation is a requirement for both Apple and Google's terms of service
- This directly impacts revenue -- every fake purchase is lost revenue.

### Warnings

**WARN-1: Hardcoded Hash Salt in SaveSystem**
- **File**: `/mnt/e/projects/MobileGameCore/Runtime/Core/SaveSystem.cs:21`
- ```csharp
  private const string HASH_SALT = "MobileGameCore_v1.0_ChangeThisInYourGame";
  ```
- The salt is a `const` string, identical across all games using the package. The comment says "Change this per game" but it cannot be changed without modifying the source. Anyone who reads the source can forge save files that pass integrity checks. Should be a `[SerializeField]` field configurable per game.

**WARN-2: Save Tampering Detected But Data Still Loaded**
- **File**: `/mnt/e/projects/MobileGameCore/Runtime/Core/SaveSystem.cs:101-111`
- When the hash integrity check fails, the system logs a warning and tracks an analytics event but continues to load the tampered data. The comment at line 105 says "Decision point: Reject save or accept with warning" but the decision was to accept. This means the integrity checking provides detection but not prevention.

**WARN-3: Save System Writes to Disk on Every Data Change**
- **File**: `/mnt/e/projects/MobileGameCore/Runtime/Core/SaveSystem.cs:199-219, 242-255, 267-280, 293-306, 311-323`
- Every `AddCurrency`, `SpendCurrency`, `UnlockLevel`, `SetLevelStars`, `Unlock`, and `ClaimDailyReward` call triggers a full save cycle (JSON serialize, SHA256 hash, Base64 encode, file write). In a game where a player collects many coins per second, this causes:
  - Disk I/O on every coin pickup
  - Frame rate drops on low-end mobile devices
  - Excessive battery drain from storage writes
- Should use a dirty flag with periodic flush (e.g., every 5 seconds or on scene change).

**WARN-4: IAPManager Single Callback Field (Race Condition)**
- **File**: `/mnt/e/projects/MobileGameCore/Runtime/Monetization/IAPManager.cs:117`
- ```csharp
  private System.Action<bool, string> currentPurchaseCallback;
  ```
- Only one purchase callback is stored. If two purchases are initiated rapidly (via UI double-tap or programmatic error), the first callback is silently overwritten. The caller of the first purchase never receives success/failure notification.

**WARN-5: SerializableDictionary Has O(n) Lookup Performance**
- **File**: `/mnt/e/projects/MobileGameCore/Runtime/Core/SaveSystem.cs:477-527`
- `TryGetValue`, `Add`, `ContainsKey`, and the indexer all use `keys.IndexOf(key)` which is O(n) linear search. For a small number of entries this is fine, but if a game stores hundreds of items in `unlockedItems` or `customData`, performance degrades. The integrity validation (`ValidateIntegrity`) adds overhead to every operation.

**WARN-6: AdManager Has Hardcoded Placeholder IDs**
- **File**: `/mnt/e/projects/MobileGameCore/Runtime/Monetization/AdManager.cs:29-30`
- ```csharp
  [SerializeField] private string androidGameID = "YOUR_ANDROID_GAME_ID";
  [SerializeField] private string iOSGameID = "YOUR_IOS_GAME_ID";
  ```
- While there is a runtime check at line 88 (`gameID.StartsWith("YOUR_")`), shipping a build with these defaults would silently disable all ad revenue. The ad unit IDs at lines 33-34 have hardcoded platform suffixes that need manual configuration.

**WARN-7: Base64 Encoding Presented as Security**
- **File**: `/mnt/e/projects/MobileGameCore/Runtime/Core/SaveSystem.cs:64-66`
- ```csharp
  // Encode (NOT encryption - just obfuscation)
  // Note: This is NOT secure encryption, just makes it non-obvious
  string encoded = Convert.ToBase64String(Encoding.UTF8.GetBytes(containerJson));
  ```
- The code comments correctly acknowledge this is not encryption, which is good. However, the overall save system (hash salt + base64 + integrity check) may give game developers a false sense of security. The documentation should make clear that determined players can trivially modify save files.

### Code Quality: 7/10

### Summary

MobileGameCore is a well-structured Unity package with excellent assembly definitions, proper UPM (Unity Package Manager) packaging, and graceful degradation via `#if` preprocessor directives for optional SDK dependencies (Unity Ads, Unity IAP, Firebase, Cloud Save). The code demonstrates solid Unity patterns: singleton with `DontDestroyOnLoad`, `[SerializeField]` for inspector configuration, comprehensive XML documentation, and proper null checking. The most significant issue is the lack of server-side IAP receipt validation, which directly impacts revenue security. The save system works but has performance concerns for write-heavy games. The ad system has good safety features (ATT compliance, emergency unpause, placeholder detection).

**Positives**: Excellent assembly definitions with version defines. Graceful degradation -- every SDK-dependent feature compiles and runs without the SDK. Integer overflow protection in currency system. ATT (App Tracking Transparency) compliance for iOS. Emergency unpause safety net after ad display. Proper UPM package.json. SHA256 integrity checking with self-repairing SerializableDictionary. Cloud Save with configurable conflict resolution strategies and offline support.

---

## Overall Assessment

### Security Posture

| Project | Auth | Secrets | Docker | Input Validation | Overall Security |
|---------|------|---------|--------|-----------------|-----------------|
| Acquisition System | None | Default passwords | Runs as root | Parameterized SQL (good) | **Poor** |
| ContractIQ | None | Clean .env.example | Runs as root | Pydantic models (good) | **Poor** |
| MobileGameCore | N/A (client) | Hardcoded salt | N/A | Good input bounds | **Fair** |

### Production Readiness

| Project | Ready? | Blocking Issues |
|---------|--------|----------------|
| Acquisition System | **No** | No auth, root container, default passwords, pickle deserialization |
| ContractIQ | **No** | No auth on healthcare data, FAISS deserialization, CORS wildcard |
| MobileGameCore | **Partially** | No IAP receipt validation (revenue risk), save performance |

### Priority Fix Order (Across All Projects)

1. **Acquisition System**: Add API authentication (JWT/API key) -- this is the most exposed system with PII data
2. **ContractIQ**: Add authentication -- healthcare data has HIPAA compliance implications
3. **Acquisition System**: Add non-root user to Dockerfile and remove default password
4. **Acquisition System**: Implement webhook signature verification (the imports are already there)
5. **MobileGameCore**: Implement server-side IAP receipt validation (direct revenue impact)
6. **Acquisition System**: Replace `pickle.load` with a safe alternative (joblib, ONNX, JSON)
7. **ContractIQ**: Restrict CORS origins and fix FAISS deserialization path security
8. **Acquisition System**: Fix `Settings()` import-time instantiation (use lazy initialization)
9. **All Projects**: Update dependencies to current versions and create lock files
10. **MobileGameCore**: Implement batched save writes with dirty flag pattern

### Code Quality Summary

| Project | Rating | Strengths | Weaknesses |
|---------|--------|-----------|------------|
| Acquisition System | **6/10** | Clean architecture, parameterized SQL, good Docker structure | No auth, stale deps, pickle risk, non-atomic transactions |
| ContractIQ | **4/10** | Multi-LLM support, good error handling | No auth, CORS wildcard, duplicate methods, fragile imports |
| MobileGameCore | **7/10** | Assembly defs, graceful degradation, good Unity patterns | Save performance, no receipt validation, hardcoded salt |

### Bottom Line

All three projects demonstrate competent software engineering at the feature level but share a common gap: **security infrastructure is missing or incomplete**. No project has authentication. Two of three Docker setups run as root. Two of three have dangerous deserialization paths. The codebases are functional prototypes that need a security hardening pass before any production deployment, especially the Acquisition System (which handles PII and has externally-accessible API endpoints) and ContractIQ (which handles healthcare data with HIPAA implications).

---

*Review completed: 2026-02-11 | All file paths are absolute | Line numbers cited from source files read during review*
