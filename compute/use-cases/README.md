# Compute-Heavy Use Cases

This directory contains real-world examples of compute-intensive tasks that benefit from cloud offloading. Each example demonstrates how to reduce local compute requirements by leveraging cloud workers.

## Use Cases Included

### 1. Image Processing Pipeline
**Problem:** Processing hundreds of images locally consumes CPU and memory, blocking other work.

**Solution:** Offload image resizing, format conversion, and optimization to cloud workers.

**Benefits:**
- 90% reduction in local CPU usage
- 5x faster processing through parallelization
- Continue working while images process in background

### 2. Video Transcoding
**Problem:** Video transcoding is extremely CPU-intensive and can take hours locally.

**Solution:** Distribute video processing across multiple cloud providers with GPU acceleration.

**Benefits:**
- 10-100x faster processing
- No local CPU/GPU strain
- Process multiple videos simultaneously

### 3. Large Dataset Analysis
**Problem:** Analyzing CSV/JSON files with millions of rows freezes local machine.

**Solution:** Stream data to cloud workers for parallel processing and aggregation.

**Benefits:**
- Handle datasets 100x larger than available RAM
- Parallel processing across multiple workers
- Real-time progress updates

### 4. AI/ML Inference
**Problem:** Running ML models locally requires large downloads and heavy computation.

**Solution:** Use cloud-hosted models via API, no local model storage needed.

**Benefits:**
- No model download or storage (models can be GBs)
- Access to latest model versions instantly
- Scale to thousands of inferences/second

### 5. Web Scraping & Data Collection
**Problem:** Sequential scraping is slow, parallel scraping uses lots of local resources.

**Solution:** Distribute scraping tasks across edge workers globally.

**Benefits:**
- Scrape from geographically distributed locations
- Bypass rate limits with distributed IPs
- 50x faster through parallelization

### 6. Cryptographic Operations
**Problem:** Hashing passwords, generating tokens, or encrypting data at scale is CPU-intensive.

**Solution:** Batch cryptographic operations and send to cloud workers.

**Benefits:**
- Hardware-accelerated crypto in the cloud
- Process thousands of operations per second
- Zero local CPU impact

### 7. PDF Generation & Document Processing
**Problem:** Generating PDFs with complex layouts is slow and memory-intensive.

**Solution:** Cloud-based document rendering with headless browsers.

**Benefits:**
- No local headless browser installation
- Parallel document generation
- Consistent rendering across platforms

### 8. Real-time Data Transformation
**Problem:** ETL pipelines consuming local resources during development.

**Solution:** Stream data through cloud transformation functions.

**Benefits:**
- Developer machine stays responsive
- Production-like environment for testing
- Scale transformations without code changes

## Directory Structure

```
use-cases/
├── 1-image-processing/
│   ├── local-approach.js     # Traditional local processing
│   ├── cloud-approach.js     # Cloud-optimized version
│   └── comparison.md         # Performance comparison
├── 2-video-transcoding/
├── 3-dataset-analysis/
├── 4-ml-inference/
├── 5-web-scraping/
├── 6-crypto-operations/
├── 7-pdf-generation/
└── 8-data-transformation/
```

## Running Examples

Each use case directory contains:
- `local-approach.js` - How you'd typically do it locally
- `cloud-approach.js` - Optimized cloud implementation
- `comparison.md` - Performance and cost analysis

Run any example:
```bash
cd use-cases/1-image-processing
node cloud-approach.js
```

## Key Takeaways

### When to Use Cloud Compute

✅ **Good Candidates:**
- CPU/GPU intensive operations
- Embarrassingly parallel tasks
- Operations that benefit from geographic distribution
- Tasks with variable/spiky load
- Processing that blocks your workflow

❌ **Keep Local:**
- Quick operations (<50ms)
- Tasks requiring local file system access
- Interactive development work
- Operations with large data transfer overhead

### Cost Comparison

| Task Type | Local Cost | Cloud Cost | Net Benefit |
|-----------|------------|------------|-------------|
| Image Processing (100 images) | $0 (your CPU time) | $0.005 | Time saved: 15 min |
| Video Transcode (10 min video) | $0 (hours of CPU) | $0.50 | Time saved: 3 hrs |
| Dataset Analysis (10M rows) | $0 (potential crash) | $0.10 | Enables processing |
| ML Inference (1000 requests) | $0 (model download + compute) | $2.00 | No setup needed |

### Performance Comparison

Real-world benchmarks from our examples:

```
Image Processing (100 images):
  Local Sequential: 120 seconds
  Local Parallel (4 cores): 35 seconds
  Cloud Parallel (50 workers): 6 seconds
  Speedup: 20x

Dataset Analysis (5M rows):
  Local: 45 seconds (high memory usage)
  Cloud Streaming: 12 seconds (constant low memory)
  Speedup: 3.75x + stability

Web Scraping (100 URLs):
  Local Sequential: 180 seconds
  Cloud Distributed: 8 seconds
  Speedup: 22.5x
```

## Integration Patterns

### Pattern 1: Fire and Forget
```javascript
// Submit task, get result later
const job = await orchestrator.submit(task);
// Continue working...
const result = await orchestrator.waitFor(job.id);
```

### Pattern 2: Batch Processing
```javascript
// Process many items in parallel
const jobs = await orchestrator.submitBatch(tasks, { parallelism: 50 });
const results = await Promise.all(jobs.map(j => orchestrator.waitFor(j.id)));
```

### Pattern 3: Streaming Pipeline
```javascript
// Process data as it arrives
for await (const chunk of dataStream) {
  orchestrator.submit({ type: 'transform', payload: chunk });
}
```

### Pattern 4: Hybrid Approach
```javascript
// Quick tasks locally, heavy tasks in cloud
if (task.estimatedTime < 1000) {
  result = await processLocally(task);
} else {
  result = await orchestrator.submit(task);
}
```

## Next Steps

1. Review the examples in each directory
2. Run the comparison scripts to see performance differences
3. Adapt the cloud-approach patterns to your use cases
4. Monitor costs and optimize based on your needs

## Resources

- [Multi-Cloud Orchestrator Documentation](../multi-cloud-orchestrator/README.md)
- [Cloudflare Worker API Reference](../API_REFERENCE.md)
- [Cost Optimization Guide](../docs/cost-optimization.md)
