# Cloud Compute Worker API Reference

## Overview

This Cloudflare Worker provides cloud-based compute capabilities to offload processing from your local machine. All endpoints require API key authentication.

**Base URL:** `https://my-first-worker.elliottsaxton.workers.dev`

**API Key Header:** `X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0`

## Rate Limits

- 100 requests per minute per IP address
- Returns 429 status code when exceeded

## Endpoints

### 1. Health Check

```bash
GET /health
```

Returns worker health status.

**Example:**
```bash
curl "https://my-first-worker.elliottsaxton.workers.dev/health" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0"
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": 1706473200000
}
```

### 2. Hello World

```bash
GET /
GET /hello
```

Basic greeting endpoint using Durable Objects with SQL storage.

**Example:**
```bash
curl "https://my-first-worker.elliottsaxton.workers.dev/hello" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0"
```

**Response:**
```json
{
  "message": "Hello, World!",
  "timestamp": 1706473200000
}
```

---

## Compute Endpoints

### 3. Hash Generation

```bash
POST /compute/hash
```

Generate SHA-256 hash of text (useful for checksum verification, password hashing, etc.)

**Request Body:**
```json
{
  "text": "your text here"
}
```

**Example:**
```bash
curl -X POST "https://my-first-worker.elliottsaxton.workers.dev/compute/hash" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, World!"}'
```

**Response:**
```json
{
  "hash": "dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f",
  "length": 13
}
```

### 4. Base64 Encoding/Decoding

```bash
POST /compute/base64
```

Encode or decode Base64 strings.

**Request Body:**
```json
{
  "operation": "encode",  // or "decode"
  "input": "your string"
}
```

**Example:**
```bash
curl -X POST "https://my-first-worker.elliottsaxton.workers.dev/compute/base64" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0" \
  -H "Content-Type: application/json" \
  -d '{"operation": "encode", "input": "Hello, World!"}'
```

**Response:**
```json
{
  "result": "SGVsbG8sIFdvcmxkIQ==",
  "operation": "encode"
}
```

### 5. JSON Transform

```bash
POST /compute/json-transform
```

Transform JSON data (stringify with pretty print or flatten nested objects).

**Request Body:**
```json
{
  "data": {"nested": {"key": "value"}},
  "transform": "flatten"  // or "stringify"
}
```

**Example:**
```bash
curl -X POST "https://my-first-worker.elliottsaxton.workers.dev/compute/json-transform" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0" \
  -H "Content-Type: application/json" \
  -d '{"data": {"user": {"name": "John", "age": 30}}, "transform": "flatten"}'
```

**Response:**
```json
{
  "result": {
    "user.name": "John",
    "user.age": 30
  }
}
```

---

## Asynchronous Job Queue

For long-running or heavy compute tasks, use the job queue system.

### 6. Submit Job

```bash
POST /jobs
```

Submit a job for asynchronous processing.

**Supported Job Types:**
- `text-analysis` - Analyze text statistics
- `data-transform` - Transform arrays of data
- `heavy-compute` - CPU-intensive calculations

**Request Body:**
```json
{
  "type": "text-analysis",
  "payload": {
    "text": "Your long text here..."
  }
}
```

**Example:**
```bash
curl -X POST "https://my-first-worker.elliottsaxton.workers.dev/jobs" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0" \
  -H "Content-Type: application/json" \
  -d '{"type": "text-analysis", "payload": {"text": "The quick brown fox jumps over the lazy dog."}}'
```

**Response:**
```json
{
  "jobId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "submitted"
}
```

### 7. Get Job Status

```bash
GET /jobs/{jobId}
```

Retrieve job status and results.

**Example:**
```bash
curl "https://my-first-worker.elliottsaxton.workers.dev/jobs/550e8400-e29b-41d4-a716-446655440000" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0"
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "type": "text-analysis",
  "status": "completed",
  "result": {
    "length": 44,
    "words": 9,
    "sentences": 1,
    "avgWordLength": 4.111,
    "uppercaseRatio": 0.022
  },
  "createdAt": 1706473200000,
  "completedAt": 1706473201000
}
```

### 8. List Jobs

```bash
GET /jobs
```

List recent jobs (up to 50 most recent).

**Example:**
```bash
curl "https://my-first-worker.elliottsaxton.workers.dev/jobs" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0"
```

**Response:**
```json
{
  "jobs": [...],
  "count": 10
}
```

---

## Job Type Details

### Text Analysis

Analyzes text and returns statistics.

```json
{
  "type": "text-analysis",
  "payload": {
    "text": "Your text here"
  }
}
```

**Result:**
```json
{
  "length": 100,
  "words": 20,
  "sentences": 3,
  "avgWordLength": 5.5,
  "uppercaseRatio": 0.05
}
```

### Data Transform

Performs operations on arrays of numbers.

```json
{
  "type": "data-transform",
  "payload": {
    "data": [5, 2, 8, 1, 9],
    "operation": "sort"  // or "sum", "average", "dedupe"
  }
}
```

**Result:**
```json
{
  "result": [1, 2, 5, 8, 9]
}
```

### Heavy Compute

CPU-intensive calculations (max 1,000,000 iterations).

```json
{
  "type": "heavy-compute",
  "payload": {
    "iterations": 100000
  }
}
```

**Result:**
```json
{
  "result": -123456.789,
  "iterations": 100000
}
```

---

## Error Responses

### 401 Unauthorized
```json
{
  "error": "Unauthorized"
}
```

### 404 Not Found
```json
{
  "error": "Not Found"
}
```

### 429 Rate Limit Exceeded
```json
{
  "error": "Rate limit exceeded"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "Detailed error message"
}
```

---

## Use Cases

### Offload Local Compute

Use this worker to offload compute-intensive tasks from your local machine:

1. **Hash generation** - Instead of computing hashes locally, send data to the edge
2. **Data processing** - Transform and analyze data in the cloud
3. **Batch operations** - Submit multiple jobs and collect results later
4. **Text analysis** - Process large documents without local CPU usage

### Integration Examples

See `examples/` folder for:
- Node.js client library
- Python integration
- CLI tool
- Batch processing scripts
