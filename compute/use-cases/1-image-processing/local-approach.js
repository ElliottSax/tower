/**
 * Image Processing - Local Approach
 *
 * Traditional approach: Process images sequentially or with limited parallelism
 * on your local machine.
 *
 * PROBLEMS:
 * - High CPU usage blocks other work
 * - Limited by number of CPU cores
 * - Memory intensive for large images
 * - Can't easily scale beyond local resources
 */

const crypto = require('crypto');

class LocalImageProcessor {
  constructor() {
    this.queue = [];
    this.processing = false;
  }

  /**
   * Simulate image processing (resize, format conversion, optimization)
   */
  async processImage(image) {
    const startTime = Date.now();

    // Simulate CPU-intensive work
    // In reality, this would use libraries like sharp, jimp, etc.
    await this.simulateResize(image);
    await this.simulateFormatConversion(image);
    await this.simulateOptimization(image);

    const duration = Date.now() - startTime;

    return {
      original: image.name,
      size: image.size,
      duration,
      processedAt: new Date().toISOString()
    };
  }

  async simulateResize(image) {
    // Simulate heavy CPU work (image resizing)
    await this.cpuIntensiveWork(300, 500);
  }

  async simulateFormatConversion(image) {
    // Simulate format conversion
    await this.cpuIntensiveWork(200, 400);
  }

  async simulateOptimization(image) {
    // Simulate optimization algorithms
    await this.cpuIntensiveWork(100, 300);
  }

  async cpuIntensiveWork(minMs, maxMs) {
    const duration = Math.floor(Math.random() * (maxMs - minMs)) + minMs;

    // Simulate CPU load
    const start = Date.now();
    while (Date.now() - start < duration) {
      // Busy wait to simulate CPU-intensive work
      crypto.createHash('sha256').update(Math.random().toString()).digest('hex');
    }
  }

  /**
   * Process images sequentially
   */
  async processSequential(images) {
    console.log(`Processing ${images.length} images sequentially...\n`);

    const results = [];
    const startTime = Date.now();

    for (let i = 0; i < images.length; i++) {
      console.log(`[${i + 1}/${images.length}] Processing ${images[i].name}...`);

      const result = await this.processImage(images[i]);
      results.push(result);

      console.log(`  ✓ Completed in ${result.duration}ms`);
    }

    const totalDuration = Date.now() - startTime;

    return {
      results,
      totalDuration,
      avgDuration: totalDuration / images.length
    };
  }

  /**
   * Process images with limited parallelism
   */
  async processParallel(images, concurrency = 4) {
    console.log(`Processing ${images.length} images (${concurrency} at a time)...\n`);

    const results = [];
    const startTime = Date.now();

    // Process in chunks
    for (let i = 0; i < images.length; i += concurrency) {
      const chunk = images.slice(i, i + concurrency);

      console.log(`Processing batch ${Math.floor(i / concurrency) + 1}...`);

      const chunkResults = await Promise.all(
        chunk.map(async (image, idx) => {
          const result = await this.processImage(image);
          console.log(`  ✓ ${image.name} completed in ${result.duration}ms`);
          return result;
        })
      );

      results.push(...chunkResults);
    }

    const totalDuration = Date.now() - startTime;

    return {
      results,
      totalDuration,
      avgDuration: totalDuration / images.length,
      concurrency
    };
  }
}

// Example usage
async function main() {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║  Image Processing - Local Approach                    ║');
  console.log('╚════════════════════════════════════════════════════════╝\n');

  // Generate test images
  const images = Array.from({ length: 20 }, (_, i) => ({
    name: `image-${i + 1}.jpg`,
    size: Math.floor(Math.random() * 5000000) + 1000000, // 1-6MB
    width: 4000,
    height: 3000
  }));

  const processor = new LocalImageProcessor();

  // Test 1: Sequential Processing
  console.log('═'.repeat(60));
  console.log('Test 1: Sequential Processing');
  console.log('═'.repeat(60) + '\n');

  const sequential = await processor.processSequential(images);

  console.log('\nResults:');
  console.log(`  Total time: ${sequential.totalDuration}ms`);
  console.log(`  Average per image: ${sequential.avgDuration.toFixed(2)}ms`);
  console.log(`  Throughput: ${(images.length / (sequential.totalDuration / 1000)).toFixed(2)} images/sec`);

  console.log('\n' + '═'.repeat(60));
  console.log('Test 2: Parallel Processing (4 concurrent)');
  console.log('═'.repeat(60) + '\n');

  const parallel = await processor.processParallel(images, 4);

  console.log('\nResults:');
  console.log(`  Total time: ${parallel.totalDuration}ms`);
  console.log(`  Average per image: ${parallel.avgDuration.toFixed(2)}ms`);
  console.log(`  Throughput: ${(images.length / (parallel.totalDuration / 1000)).toFixed(2)} images/sec`);
  console.log(`  Speedup vs sequential: ${(sequential.totalDuration / parallel.totalDuration).toFixed(2)}x`);

  console.log('\n' + '═'.repeat(60));
  console.log('Limitations of Local Processing:');
  console.log('═'.repeat(60));
  console.log('❌ High CPU usage (100% during processing)');
  console.log('❌ Blocks other work on your machine');
  console.log('❌ Limited by CPU cores (4x speedup max on 4-core CPU)');
  console.log('❌ Memory intensive for large images');
  console.log('❌ Cannot easily scale beyond local resources');
  console.log('❌ Slow for large batches (20 images took ' + (parallel.totalDuration / 1000).toFixed(1) + 's)');
  console.log('\n💡 See cloud-approach.js for a better solution!\n');
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = LocalImageProcessor;
