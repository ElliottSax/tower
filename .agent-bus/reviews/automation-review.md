# Content Automation Projects - Deep Code Review

**Reviewer:** Claude Opus 4.6 (Senior Security & Automation Reviewer)
**Date:** 2026-02-11
**Projects:** BookCLI, Pod (Print-on-Demand), OYKH, Toonz

---

## 1. Executive Summary

| Project | Grade | LOC (est.) | Risk Level | Key Concern |
|---------|-------|------------|------------|-------------|
| **BookCLI** | **D** | ~15,000+ | **CRITICAL** | Live API keys committed in plaintext; shell injection; KDP cookie security |
| **Pod** | **C-** | ~8,000+ | **HIGH** | Live API keys in .env committed; Etsy OAuth token stored world-readable |
| **OYKH** | **C** | ~4,000+ | **HIGH** | YouTube OAuth pickle deserialization; API keys in .env committed |
| **Toonz** | **C+** | ~6,000+ | **MEDIUM** | No authentication on API; CORS wildcard; hardcoded DB credentials |

**Overall Verdict:** All four projects have the same catastrophic issue -- live, real API keys committed to version control in plaintext .env files and a dedicated `api_keys.json` file. This is the single most urgent finding. Beyond that, each project has automation-specific concerns around cost controls, error recovery, and session security.

---

## 2. Critical Issues (Must Fix Immediately)

### CRIT-01: Live API Keys Committed to Git (ALL PROJECTS)
**Severity: CATASTROPHIC**
**Files:**
- `/mnt/e/projects/bookcli/.env:1-19` -- 11+ live API keys (Groq, OpenRouter, Together, GitHub PAT, DeepSeek, HuggingFace, Cerebras, Cloudflare, etc.)
- `/mnt/e/projects/bookcli/api_keys.json:1-13` -- Duplicate keys in JSON format including Replicate token
- `/mnt/e/projects/pod/.env:23-48` -- Live keys for Gemini, Printful, fal.ai, SiliconFlow, DeepSeek, Replicate, Etsy API
- `/mnt/e/projects/oykh/.env:1-2` -- Moonshot API key
- `/mnt/e/projects/oykh/.env.txt:1` -- OpenAI API key labeled as OPENAI_API_KEY (but is actually a DeepSeek key)

**Impact:** Any person or service with read access to this git repo (including GitHub if pushed, CI/CD runners, backup systems) can extract every API key and run up unlimited charges. The GitHub PAT (`github_pat_11AVDLDRY...`) grants repository access. The Cloudflare token and account ID grant cloud infrastructure access.

**Evidence:** The `.gitignore` files DO list `.env` patterns, but `git ls-files` shows these files are not currently tracked in git's index. However, the git status output shows them as untracked (`??`), which means they exist on disk but are gitignored. This is better than being committed, but they have been readable in tool outputs and could easily be accidentally staged. The `api_keys.json` file is NOT in the .gitignore pattern (the pattern is `config/api_keys.json`, not the root-level one).

**Recommendation:**
1. Rotate ALL exposed API keys immediately
2. Add `/api_keys.json` explicitly to `.gitignore` (currently only `config/api_keys.json` is covered)
3. Run `git log --all --full-history -- "*.env" "api_keys.json"` to verify keys were never committed historically
4. Delete `api_keys.json` entirely -- it duplicates `.env` and is harder to gitignore
5. Consider using a secrets manager (e.g., `pass`, `1password-cli`, or AWS Secrets Manager)

### CRIT-02: KDP Session Cookies Stored Insecurely (BookCLI)
**Severity: HIGH**
**File:** `/mnt/e/projects/bookcli/publishing/kdp_uploader.py:118,176-178,198-200`

```python
cookies_file = Path.home() / ".kdp_cookies.json"
cookies_file.write_text(json.dumps(cookies, indent=2))
```

Amazon KDP session cookies are saved to `~/.kdp_cookies.json` in plaintext JSON with no file permission restrictions. Anyone with read access to the home directory can hijack the Amazon KDP session.

**Impact:** Full access to the Amazon KDP account -- can publish books, modify pricing, access financial information, download tax documents.

**Recommendation:**
1. Set file permissions to 0600 after writing: `os.chmod(cookies_file, 0o600)`
2. Consider encrypting cookies at rest using the Fernet key from `security/config_manager.py`
3. Add expiry checking -- stale cookies should be deleted
4. Add `~/.kdp_cookies.json` to a global gitignore

### CRIT-03: YouTube OAuth Token Stored via Pickle (OYKH)
**Severity: HIGH**
**File:** `/mnt/e/projects/oykh/youtube_uploader.py:78-79,102-103`

```python
with open(self.token_file, 'rb') as token:
    creds = pickle.load(token)
```

YouTube OAuth credentials are serialized/deserialized using Python's `pickle` module. Pickle deserialization of untrusted data is a known remote code execution vector. While the file is locally generated, if an attacker modifies `youtube_token.json`, arbitrary code execution occurs on next load.

Additionally, the token file has no permission restrictions and is stored in the project directory root (not `~/.config/`), making it more likely to be accidentally committed.

**Impact:** RCE if token file is tampered with; YouTube channel access if file is leaked.

**Recommendation:**
1. Replace `pickle` with `json` serialization (Google's credentials can be serialized to JSON)
2. Store token in `~/.config/oykh/youtube_token.json` with 0600 permissions
3. Add `youtube_token.json` and `oauth_credentials.json` to `.gitignore`

### CRIT-04: Shell Injection via subprocess with shell=True (BookCLI)
**Severity: HIGH**
**File:** `/mnt/e/projects/bookcli/generators/platform_publisher.py:198-200`

```python
result = subprocess.run(
    ["~/.local/bin/magick", "identify", "-format", "%w %h", str(image_path)],
    capture_output=True, text=True, shell=True
)
```

Using `shell=True` with a list argument is dangerous and counterintuitive -- the list is joined into a single string and passed to the shell. The `image_path` variable comes from filesystem traversal and is not sanitized. A malicious filename like `; rm -rf /` would execute shell commands.

**Impact:** Arbitrary command execution if processing files with crafted filenames.

**Recommendation:** Remove `shell=True`. The command is already a list, so it works correctly without shell interpretation. Also, `~/.local/bin/magick` won't expand without shell=True anyway -- use `os.path.expanduser()` or `shutil.which()`.

### CRIT-05: Etsy OAuth Tokens Stored World-Readable (Pod)
**Severity: HIGH**
**File:** `/mnt/e/projects/pod/app/services/etsy_oauth_client.py:102-103,127-133`

```python
self.token_file = Path(token_file or os.path.expanduser("~/.etsy_tokens.json"))
# ...
with open(self.token_file, 'w') as f:
    json.dump(self.tokens, f, indent=2)
```

Etsy OAuth access and refresh tokens are stored in `~/.etsy_tokens.json` with default file permissions (likely 0644 on most Linux systems). The refresh token grants persistent access to the Etsy shop.

**Impact:** Etsy shop takeover -- listing creation/deletion, transaction access, shop settings modification.

**Recommendation:** Set file permissions to 0600 after writing.

---

## 3. Warnings (Should Fix)

### WARN-01: No Cost Controls or Spending Limits (ALL PROJECTS)
**Severity: MEDIUM-HIGH**

None of the projects implement hard spending caps:

- **BookCLI** (`lib/api_client.py`): Has per-API rate limiting (calls/minute) and usage tracking with cost estimation, but NO hard cap that stops execution when a dollar threshold is reached. A bug in the batch generator could make thousands of API calls.
- **Pod** (`app/core/config.py:67-68`): Has `max_designs_per_day=100` and `max_api_calls_per_minute=60`, but no dollar-amount cap. 100 DALL-E calls = $4-8, but 100 Replicate calls = $0.30.
- **OYKH** (`batch_video_generator.py`): No cost tracking at all. Each video costs ~$0.25-$5 depending on pipeline. Batch mode with 100 topics and retries could cost $500+.
- **Toonz** (`pipeline/api.py:155-160`): Has render pricing defined but usage tracking is in-memory only and lost on restart.

**Recommendation:** Add a global `MAX_DAILY_SPEND_USD` env var and a persistent cost tracker that halts all API calls when exceeded.

### WARN-02: No Authentication on Toonz API (Toonz)
**Severity: MEDIUM-HIGH**
**File:** `/mnt/e/projects/toonz/pipeline/api.py:306-311,494-510`

```python
@app.post("/api/v1/renders", response_model=RenderStatus)
async def create_render(
    request: RenderRequest,
    background_tasks: BackgroundTasks,
    user_id: str = Query("demo_user", description="User ID for billing")
):
```

The API has NO authentication. The `user_id` is a query parameter defaulting to "demo_user" -- anyone can impersonate any user. The admin stats endpoint (`/api/v1/admin/stats`) is completely unprotected. Comments say "In production, add authentication" but the code is marked as "REVENUE-READY" in CLAUDE.md.

**Impact:** Unlimited free renders, admin data exposure, potential DoS via batch endpoint (100 renders per batch).

### WARN-03: CORS Wildcard Configuration (Toonz)
**Severity: MEDIUM**
**File:** `/mnt/e/projects/toonz/pipeline/api.py:132-138`

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

Using `allow_origins=["*"]` with `allow_credentials=True` is a dangerous combination. While modern browsers block this specific combo, it signals a lack of production hardening.

### WARN-04: Hardcoded Database Credentials (Toonz, Pod)
**Severity: MEDIUM**
**Files:**
- `/mnt/e/projects/toonz/docker-compose.yml:33-35`: `POSTGRES_PASSWORD: toonz`
- `/mnt/e/projects/pod/.env:9`: `DATABASE_PASSWORD=pod_secure_password`

Docker Compose uses hardcoded credentials. The Pod .env has "pod_secure_password" as the database password.

### WARN-05: Bare Except Clauses Swallowing Errors (BookCLI)
**Severity: MEDIUM**
**File:** `/mnt/e/projects/bookcli/publishing/kdp_uploader.py:248,319,338,429,460`

Multiple bare `except:` clauses silently swallow all exceptions including `KeyboardInterrupt` and `SystemExit`. In a browser automation context, this means:
- Failed uploads may appear to succeed
- Browser processes may leak (never closed)
- The batch publisher could continue with corrupted state

```python
except:  # Lines 248, 319, 338, 429, 460
    pass
```

### WARN-06: KDP Batch Publisher Has No Confirmation in Dry-Run Bypass (BookCLI)
**Severity: MEDIUM**
**File:** `/mnt/e/projects/bookcli/publishing/batch_kdp_publisher.py:370-379`

The confirmation prompt (`Proceed? (yes/no)`) only appears when NOT in dry-run mode. However, the `max_books_per_session` default of 10 with a 5-minute delay means a full batch run takes ~50 minutes of irreversible Amazon publishing.

### WARN-07: YouTube Uploader Defaults to Private but Has No Quota Management (OYKH)
**Severity: MEDIUM**
**File:** `/mnt/e/projects/oykh/youtube_uploader.py:148-149`

Videos default to `privacy='private'` which is safe. However, there's no YouTube API quota tracking. YouTube Data API has a daily quota of 10,000 units; each upload costs 1,600 units, meaning only ~6 uploads per day. The batch uploader has no awareness of this limit and will fail silently after quota exhaustion.

### WARN-08: Fernet Encryption Key Handling Bug (BookCLI)
**Severity: MEDIUM**
**File:** `/mnt/e/projects/bookcli/security/config_manager.py:72`

```python
self.cipher = Fernet(encryption_key[:32].ljust(32, b'0'))
```

Fernet keys must be 32 bytes, URL-safe base64 encoded (resulting in 44 characters). This code truncates to 32 bytes and pads with zeros, which:
1. Will produce an invalid Fernet key (not base64-encoded)
2. Will raise `ValueError` at runtime
3. The fallback of generating a new key on every restart means encrypted data is irrecoverable

---

## 4. Minor Issues (Nice to Fix)

### MINOR-01: Duplicate API Key Definitions (BookCLI)
**File:** `/mnt/e/projects/bookcli/.env:2-5`
`OPENROUTER_KEY` and `OPENROUTER_API_KEY` are both defined with the same value. `TOGETHER_KEY` and `TOGETHER_API_KEY` likewise. This creates confusion about which variable name is canonical.

### MINOR-02: Hardcoded sys.path Manipulation (OYKH)
**File:** `/mnt/e/projects/oykh/batch_video_generator.py:23`
```python
sys.path.insert(0, '/mnt/e/projects/OYKH')
```
Hardcoded absolute path that will break on any other machine. Should use relative imports or proper package installation.

### MINOR-03: In-Memory Job Storage with No Persistence (Toonz)
**File:** `/mnt/e/projects/toonz/pipeline/api.py:145-148`
```python
JOBS: Dict[str, RenderStatus] = {}
USAGE: Dict[str, UsageStats] = {}
```
All job data and usage tracking is in-memory Python dicts. Server restart loses all state. The docker-compose includes Redis and PostgreSQL, but the API code doesn't use them.

### MINOR-04: Temp File Cleanup (Toonz)
**File:** `/mnt/e/projects/toonz/pipeline/api.py:147`
Render outputs go to `tempfile.gettempdir() / "toonz_renders"` but are never cleaned up. Over time this will fill up disk.

### MINOR-05: Missing .gitignore for Toonz
The toonz project has NO `.gitignore` file at all. Generated outputs, Python caches, and potentially sensitive files could be committed.

### MINOR-06: Email Logged in KDP Login (BookCLI)
**File:** `/mnt/e/projects/bookcli/publishing/kdp_uploader.py:146`
```python
logger.info(f"Logging into KDP as {self.email}...")
```
PII (email address) logged at INFO level. Should be DEBUG or masked.

### MINOR-07: Password Accepted via CLI Argument (BookCLI, OYKH)
**Files:**
- `/mnt/e/projects/bookcli/publishing/kdp_uploader.py:536`: `--password` CLI arg
- `/mnt/e/projects/bookcli/publishing/batch_kdp_publisher.py:312`: `--password` CLI arg

Passwords on the command line are visible in `ps aux`, shell history, and process listings. Should use env vars or prompt interactively.

### MINOR-08: No requirements.txt or pyproject.toml (OYKH)
The OYKH project has no dependency specification file. Dependencies must be guessed from imports.

---

## 5. Positive Findings

### BookCLI
- **Well-structured API client** (`lib/api_client.py`): Implements circuit breaker, rate limiting, round-robin fallback, response caching, usage tracking, and connection pooling. This is genuinely production-quality code (~1,500 LOC).
- **Dry-run mode** for KDP publishing prevents accidental publishes during testing.
- **Comprehensive .gitignore** covering secrets, API keys, and sensitive patterns.
- **Confirmation prompt** before batch publishing non-dry-run.
- **Rate limiting** between batch KDP uploads (5-minute delay default).
- **Session cookie reuse** reduces login frequency and 2FA prompts.
- **Secure config manager** (`security/config_manager.py`) encrypts sensitive values in memory (though the Fernet key handling has a bug).
- **Extensive test suite** with unit and integration tests.
- **Config validation** with custom `ConfigValidationError` and thorough boundary checks.

### Pod
- **Pydantic settings** (`app/core/config.py`) with validation and type safety.
- **JWT authentication** properly implemented in `app/utils/auth.py`.
- **PKCE OAuth flow** for Etsy (security best practice).
- **Token refresh logic** with 5-minute expiry buffer.
- **Proper timeout handling** on all HTTP requests.
- **Rate limiting** configured at both API and application level.

### OYKH
- **Checkpoint/resume system** (`batch_video_generator.py`): Saves state to JSON, can resume interrupted batches. This is essential for overnight generation.
- **Clean config architecture** (`config.py`): Dataclass-based config with environment detection, validation, and singleton pattern.
- **Retry logic** with max attempts per video job.
- **Private-by-default** YouTube uploads.
- **Good .env.example** with cost comparison documentation.

### Toonz
- **Clean API design** with Pydantic request/response models.
- **Background task processing** using FastAPI's BackgroundTasks.
- **Rate limiting** per user with subscription tiers.
- **Docker Compose** with proper service dependencies.
- **Comprehensive test suite** (~867 pipeline tests per CLAUDE.md).
- **Health check endpoint** for container orchestration.

---

## 6. Automation-Specific Assessment

### Idempotency
| Project | Safe to Re-run? | Notes |
|---------|----------------|-------|
| BookCLI | Partial | Batch publisher uses `.kdp_published` marker files to avoid re-publishing. Good. But no deduplication in book generation. |
| Pod | Yes | Design generation creates unique filenames; Etsy upload uses CSV export (manual step). |
| OYKH | Yes | Checkpoint system tracks job status; completed jobs are skipped on resume. |
| Toonz | Yes | Each render gets a UUID; no side effects on re-request. |

### Error Recovery
| Project | Recovery | Notes |
|---------|----------|-------|
| BookCLI | Good | Circuit breaker, fallback APIs, retry with backoff. KDP uploader takes error screenshots. |
| Pod | Good | Pydantic validation, HTTP error handling, timeout handling. |
| OYKH | Good | 3-attempt retry per job, checkpoint saves after each job, resume from checkpoint. |
| Toonz | Poor | Failed renders update status but no retry mechanism. In-memory state lost on restart. |

### Cost Risk Assessment
| Project | Max Unattended Spend | Safeguards |
|---------|---------------------|------------|
| BookCLI | ~$50/session | Rate limiting per API; max_books_per_session=10; but no dollar cap |
| Pod | ~$10/day | max_designs_per_day=100; cheapest backends selected |
| OYKH | ~$500/batch | No cost tracking; batch generator has no limits beyond topic count |
| Toonz | ~$50/day | Per-user render limits; subscription tiers; but no auth enforcement |

---

## 7. Priority Remediation Order

1. **Rotate all exposed API keys** (affects all projects, hours not days)
2. **Delete `api_keys.json`** from BookCLI root
3. **Fix shell=True injection** in `platform_publisher.py`
4. **Replace pickle with JSON** for YouTube OAuth tokens
5. **Add file permission restrictions** (0600) to all token/cookie files
6. **Add authentication to Toonz API** before any public deployment
7. **Add global spending cap** with persistent tracking
8. **Fix Fernet key handling** in BookCLI config manager
9. **Add .gitignore** to Toonz project
10. **Replace bare except clauses** in KDP uploader

---

*Review completed 2026-02-11. All file references are absolute paths.*
