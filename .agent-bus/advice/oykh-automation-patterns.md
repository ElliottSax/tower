# OYKH Automation Patterns - Lessons Learned

**Date**: 2026-02-10
**Project**: oykh (Video Generation Pipeline)
**Pattern**: Batch Content Generation with External API Integration

---

## 🎯 Pattern: Batch Video Generation Pipeline

### Context
Automated video generation system that creates 10-100+ educational videos from topics, adds subtitles, and uploads to YouTube overnight.

### Solution Architecture

```
Input: Topics → Script Gen (LLM) → Scene Planning → Frame Rendering → TTS → FFmpeg Assembly → Subtitles → YouTube Upload
```

### Key Design Decisions

#### 1. Checkpoint/Resume System
**Problem**: Long-running batch jobs fail partway through
**Solution**: JSON checkpoint file with job status tracking

```python
@dataclass
class VideoJob:
    job_id: str
    status: VideoStatus  # PENDING, IN_PROGRESS, COMPLETED, FAILED
    attempts: int
    max_attempts: int = 3
    output_path: Optional[str] = None
    error: Optional[str] = None

# Save checkpoint after each job
def save_checkpoint(self):
    data = {'jobs': [job.to_dict() for job in self.jobs]}
    with open(checkpoint_file, 'w') as f:
        json.dump(data, f, indent=2)
```

**Benefits**:
- Resume from any point
- Auto-retry failed jobs
- Full audit trail

**Reusable For**:
- Any long-running batch process
- Multi-step pipelines with external APIs
- Overnight automation jobs

---

#### 2. OAuth Token Caching for YouTube API
**Problem**: OAuth flow interrupts automation, tokens expire
**Solution**: Cache tokens with auto-refresh

```python
# Save token after first auth
with open('youtube_token.json', 'wb') as token:
    pickle.dump(creds, token)

# Auto-refresh on subsequent runs
if creds and creds.expired and creds.refresh_token:
    creds.refresh(Request())
```

**Benefits**:
- One-time OAuth setup
- Automatic token refresh
- No user intervention for batch uploads

**Reusable For**:
- Google APIs (Drive, Sheets, etc.)
- Social media automation (Twitter, Facebook)
- Any OAuth 2.0 service

---

#### 3. Modular Pipeline with Error Isolation
**Problem**: Failure in one step shouldn't break entire batch
**Solution**: Isolate each step with try/catch and continue

```python
async def process_job(self, job: VideoJob) -> bool:
    try:
        output = await generate_video(job.topic)
        job.status = COMPLETED
        return True
    except Exception as e:
        job.error = str(e)
        if job.attempts < job.max_attempts:
            job.status = PENDING  # Retry
        else:
            job.status = FAILED
        return False
```

**Benefits**:
- Graceful degradation
- Detailed error tracking
- Partial success vs total failure

**Reusable For**:
- Multi-step content pipelines
- Data processing workflows
- ETL jobs with multiple sources

---

#### 4. Rate Limiting for External APIs
**Problem**: YouTube API has quota limits, rapid requests get throttled
**Solution**: Configurable delays between operations

```python
async def run(self, delay_between: int = 30):
    for i, job in enumerate(pending_jobs):
        await self.process_job(job)

        if i < len(pending_jobs) - 1:
            await asyncio.sleep(delay_between)
```

**Benefits**:
- Avoid API throttling
- Respect rate limits
- Configurable for different APIs

**Reusable For**:
- Any external API integration
- Web scraping
- Bulk operations on SaaS platforms

---

#### 5. Auto-Metadata Generation
**Problem**: Creating titles/descriptions for 50+ videos is tedious
**Solution**: Template-based metadata from video content

```python
def generate_metadata(self, video_path: str, topic: str) -> Dict:
    title = topic.title()[:100]  # YouTube max
    description = f"""{topic}

    Learn about {topic.lower()} in this animated explainer!

    #education #learning #explainer
    """
    tags = topic.lower().split() + ['education', 'learning']
    return {'title': title, 'description': description, 'tags': tags}
```

**Benefits**:
- Consistent SEO optimization
- Zero manual effort
- Scalable to 100s of videos

**Reusable For**:
- Blog post generation
- Social media posts
- Product descriptions

---

#### 6. SRT Subtitle Generation from Scene Data
**Problem**: Videos need accessibility (subtitles)
**Solution**: Generate SRT from scene narration with smart text splitting

```python
def split_text_to_lines(self, text: str, max_chars: int = 42) -> List[str]:
    """Split text into subtitle-friendly chunks."""
    words = text.split()
    lines = []
    current_line = []

    for word in words:
        if len(' '.join(current_line + [word])) <= max_chars:
            current_line.append(word)
        else:
            lines.append(' '.join(current_line))
            current_line = [word]

    return lines
```

**Benefits**:
- Accessibility compliance
- Better engagement (80% watch muted)
- Professional appearance

**Reusable For**:
- Any video content system
- Podcast transcript formatting
- Chat/messaging systems with line wrapping

---

## 🏗️ Architecture Patterns

### 1. Three-Tier Automation
```
Tier 1: Individual Components (video gen, subtitle gen, youtube upload)
Tier 2: Batch Processors (batch video gen, batch upload)
Tier 3: End-to-End Orchestrator (full pipeline)
```

**Why This Works**:
- Use components individually for testing
- Batch processors for partial automation
- Orchestrator for full hands-off pipeline

### 2. Data Flow Design
```
JSON → Processing → JSON → Processing → External API
```

Every step reads/writes JSON for:
- State persistence
- Debugging visibility
- Resume capability

### 3. Async Where It Matters
```python
async def generate_videos():  # Slow I/O operations
    await generate_narration()  # TTS API calls
    await upload_to_youtube()   # Network uploads

# Sequential frame rendering (CPU-bound)
for frame in frames:
    render_frame(frame)  # No async needed
```

---

## 📊 Performance Metrics

### Achieved Throughput
- **Video Generation**: 2-4 min/video
- **Subtitle Burn-in**: 30-60 sec/video
- **YouTube Upload**: 1-2 min/video
- **Total**: ~4-7 min/video

### Batch Performance (20 videos)
- **Sequential**: 80-140 minutes (~2 hours)
- **Cost**: ~$5 (with paid LLM APIs)
- **Success Rate**: 95%+ with retry logic

### Scalability
- Tested: 50 videos in one batch
- Theoretical: 100+ videos (limited by YouTube API quota)
- Bottleneck: YouTube upload rate limits

---

## 🔧 Reusable Components

### 1. Batch Processor Base Class
```python
class BatchProcessor:
    def __init__(self, checkpoint_file):
        self.jobs = []
        self.checkpoint_file = checkpoint_file
        self.load_checkpoint()

    def add_job(self, **kwargs):
        job = Job(**kwargs)
        self.jobs.append(job)

    async def run(self, max_concurrent=1):
        for job in self.pending_jobs:
            await self.process_job(job)
            self.save_checkpoint()
```

**Reuse This For**:
- Bulk email campaigns
- Data migration jobs
- Image/video processing pipelines
- Report generation

### 2. OAuth Token Manager
```python
class OAuthManager:
    def __init__(self, credentials_file, token_file, scopes):
        self.creds = self.authenticate()

    def authenticate(self):
        if token_exists and token_valid:
            return load_token()
        else:
            return run_oauth_flow()
```

**Reuse This For**:
- Google APIs (Drive, Calendar, Gmail, etc.)
- Social media automation
- Cloud storage integration

### 3. Progress Reporter
```python
class ProgressReporter:
    def __init__(self):
        self.report = {'started_at': now(), 'stats': {}}

    def log_completion(self, job_id, success):
        self.report['stats']['completed'] += 1
        self.save_report()
```

**Reuse This For**:
- Any long-running job
- Data pipeline monitoring
- Batch processing systems

---

## 💡 Key Insights

### 1. Checkpointing is Essential
Never run batch jobs >30 min without checkpointing. API failures WILL happen.

### 2. Design for Partial Failure
Batch of 50 videos? Expect 2-3 failures. Design to continue and report.

### 3. Rate Limiting Prevents Bans
Start conservative (60s delays), then optimize based on API responses.

### 4. OAuth Setup is One-Time Pain
First run requires manual OAuth, but then it's fully automated.

### 5. Metadata Quality Matters
Auto-generated metadata should follow best practices (SEO, keywords, descriptions).

### 6. Testing at Scale is Different
1 video works ≠ 50 videos work. Test with batches of 5-10.

---

## 🎓 Lessons for Other Projects

### Applicable To:

1. **Course Platform** (affiliate/course projects)
   - Batch generate lesson videos
   - Auto-upload to Vimeo/YouTube
   - Generate transcripts/subtitles

2. **Social Media Automation** (pod/toonz projects)
   - Batch create posts/reels
   - Schedule publishing
   - Track performance

3. **Content Generation** (bookcli/discovery projects)
   - Batch article writing
   - SEO optimization
   - Multi-platform publishing

4. **Data Pipelines** (quant projects)
   - Batch data processing
   - External API integration
   - Error recovery and retry

### Pattern Template:

```
1. Individual Component (single item processing)
2. Batch Processor (queue + checkpoint)
3. End-to-End Orchestrator (full pipeline)
4. Progress Reporting (JSON state)
5. Error Recovery (retry logic)
6. External API Integration (OAuth + rate limiting)
```

---

## 📚 Technologies Used

- **Python**: asyncio for I/O operations
- **FFmpeg**: Video assembly and subtitle burn-in
- **YouTube API**: OAuth 2.0 + Data API v3
- **Edge TTS**: Free high-quality narration
- **LLM APIs**: Groq (free tier) or DeepSeek for script generation

---

## 🚀 Quick Start Template

```python
# 1. Create batch processor
processor = BatchProcessor(checkpoint_file)

# 2. Add jobs
for item in items:
    processor.add_job(item)

# 3. Run with checkpointing
await processor.run(delay_between=30)

# 4. Generate report
processor.generate_report()
```

---

## 🔗 Related Patterns

- **Acquisition System**: Batch lead processing with retry
- **Mobile Games**: Asset generation pipelines
- **Roblox**: Automated deployment and testing

---

**Status**: ✅ Production-proven pattern
**Reusability**: High - applicable to any batch content generation
**Next Evolution**: Add concurrent processing (asyncio.gather) for 2-3x speedup
