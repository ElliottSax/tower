/**
 * Multi-Cloud Compute Orchestrator
 *
 * Routes compute tasks to optimal cloud providers based on:
 * - Task type and requirements
 * - Provider availability and health
 * - Cost constraints
 * - Latency requirements
 * - Geographic location
 */

const EventEmitter = require('events');
const CloudflareProvider = require('./providers/cloudflare');
const AWSProvider = require('./providers/aws');
const GCPProvider = require('./providers/gcp');
const LocalProvider = require('./providers/local');
const DeepSeekProvider = require('./providers/deepseek');
const GroqProvider = require('./providers/groq');
const TogetherProvider = require('./providers/together');
const CerebrasProvider = require('./providers/cerebras');
const ReplicateProvider = require('./providers/replicate');
const HuggingFaceProvider = require('./providers/huggingface');
const OpenRouterProvider = require('./providers/openrouter');

class Orchestrator extends EventEmitter {
  constructor(config = {}) {
    super();
    this.config = config;
    this.providers = new Map();
    this.jobs = new Map();
    this.stats = {
      totalJobs: 0,
      completedJobs: 0,
      failedJobs: 0,
      totalCost: 0,
      providerStats: {}
    };

    this.initializeProviders();
  }

  initializeProviders() {
    // Initialize enabled providers
    const providers = [
      { name: 'cloudflare', class: CloudflareProvider },
      { name: 'aws', class: AWSProvider },
      { name: 'gcp', class: GCPProvider },
      { name: 'deepseek', class: DeepSeekProvider },
      { name: 'groq', class: GroqProvider },
      { name: 'together', class: TogetherProvider },
      { name: 'cerebras', class: CerebrasProvider },
      { name: 'replicate', class: ReplicateProvider },
      { name: 'huggingface', class: HuggingFaceProvider },
      { name: 'openrouter', class: OpenRouterProvider },
      { name: 'local', class: LocalProvider }
    ];

    for (const { name, class: ProviderClass } of providers) {
      const providerConfig = this.config[name] || {};
      if (providerConfig.enabled !== false) {
        const provider = new ProviderClass(providerConfig);
        this.providers.set(name, provider);
        this.stats.providerStats[name] = {
          jobs: 0,
          cost: 0,
          avgLatency: 0,
          failures: 0
        };
      }
    }

    console.log(`Initialized ${this.providers.size} providers`);
  }

  /**
   * Submit a task for execution
   */
  async submit(task) {
    const jobId = this.generateJobId();

    const job = {
      id: jobId,
      task,
      status: 'pending',
      provider: null,
      submittedAt: Date.now(),
      startedAt: null,
      completedAt: null,
      result: null,
      error: null,
      cost: 0
    };

    this.jobs.set(jobId, job);
    this.stats.totalJobs++;

    // Select optimal provider
    const provider = await this.selectProvider(task);

    if (!provider) {
      job.status = 'failed';
      job.error = 'No available provider';
      this.stats.failedJobs++;
      this.emit('job:failed', job);
      return job;
    }

    job.provider = provider.name;
    job.status = 'submitted';
    this.emit('job:submitted', job);

    // Execute asynchronously
    this.executeJob(job, provider).catch(error => {
      console.error(`Job ${jobId} execution error:`, error);
    });

    return job;
  }

  /**
   * Submit multiple tasks in batch
   */
  async submitBatch(tasks, options = {}) {
    const { parallelism = 10 } = options;
    const jobs = [];

    // Process in chunks
    for (let i = 0; i < tasks.length; i += parallelism) {
      const chunk = tasks.slice(i, i + parallelism);
      const chunkJobs = await Promise.all(
        chunk.map(task => this.submit(task))
      );
      jobs.push(...chunkJobs);
    }

    return jobs;
  }

  /**
   * Get job status
   */
  async getStatus(jobId) {
    const job = this.jobs.get(jobId);
    if (!job) {
      throw new Error(`Job ${jobId} not found`);
    }
    return job;
  }

  /**
   * Wait for job completion
   */
  async waitFor(jobId, timeout = 60000) {
    const startTime = Date.now();

    while (Date.now() - startTime < timeout) {
      const job = await this.getStatus(jobId);

      if (job.status === 'completed') {
        return job.result;
      } else if (job.status === 'failed') {
        throw new Error(job.error || 'Job failed');
      }

      await new Promise(resolve => setTimeout(resolve, 500));
    }

    throw new Error(`Job ${jobId} timeout after ${timeout}ms`);
  }

  /**
   * Select optimal provider for a task
   */
  async selectProvider(task) {
    const ranked = this.selectRankedProviders(task);
    return ranked.length > 0 ? ranked[0] : null;
  }

  /**
   * Select providers ranked by suitability for a task.
   * Returns an array of providers sorted best-to-worst.
   * Excludes providers that are unavailable or in cooldown.
   */
  selectRankedProviders(task, excludeProviders = []) {
    const { type, requirements = {}, provider: forcedProvider } = task;

    // If provider is specified, use only that one (if available)
    if (forcedProvider && this.providers.has(forcedProvider)) {
      const p = this.providers.get(forcedProvider);
      if (p.isAvailable() && !excludeProviders.includes(p.name)) {
        return [p];
      }
      return [];
    }

    // Get available providers, excluding any already tried
    const availableProviders = Array.from(this.providers.values())
      .filter(p => p.isAvailable() && !excludeProviders.includes(p.name));

    if (availableProviders.length === 0) {
      return [];
    }

    // Score each provider
    const scores = availableProviders.map(provider => ({
      provider,
      score: this.scoreProvider(provider, task, requirements)
    }));

    // Sort by score (higher is better)
    scores.sort((a, b) => b.score - a.score);

    return scores.map(s => s.provider);
  }

  /**
   * Score a provider for a given task
   */
  scoreProvider(provider, task, requirements) {
    let score = 0;

    // Task type compatibility
    const typeScore = provider.getTaskScore(task.type);
    score += typeScore * 40;

    // Latency requirements
    if (requirements.latency === 'low' && provider.latency === 'low') {
      score += 30;
    } else if (requirements.latency === 'medium') {
      score += 20;
    }

    // Cost optimization
    const providerCost = provider.estimateCost(task);
    if (requirements.cost === 'minimize') {
      score += (1 / (providerCost + 0.01)) * 20;
    } else if (requirements.cost === 'performance') {
      score -= providerCost * 5;
    }

    // Provider health and reliability
    const stats = this.stats.providerStats[provider.name];
    if (stats) {
      const successRate = stats.jobs > 0
        ? (stats.jobs - stats.failures) / stats.jobs
        : 1;
      score += successRate * 10;
    }

    // Priority from config
    const priority = provider.config.priority || 5;
    score += priority;

    return score;
  }

  /**
   * Execute a job on a provider, with automatic fallback to other providers on failure.
   * Maximum of 3 fallback attempts to prevent infinite loops.
   */
  async executeJob(job, provider) {
    const maxFallbacks = 3;
    const triedProviders = [];
    let currentProvider = provider;

    for (let attempt = 0; attempt <= maxFallbacks; attempt++) {
      try {
        job.status = 'running';
        job.provider = currentProvider.name;
        if (attempt === 0) {
          job.startedAt = Date.now();
        }
        this.emit('job:started', job);

        const result = await currentProvider.execute(job.task);

        // Success - record it and update stats
        currentProvider.recordSuccess();

        job.status = 'completed';
        job.completedAt = Date.now();
        job.result = result;
        job.cost = currentProvider.estimateCost(job.task);

        // Update stats
        this.stats.completedJobs++;
        this.stats.totalCost += job.cost;

        const providerStats = this.stats.providerStats[currentProvider.name];
        if (providerStats) {
          providerStats.jobs++;
          providerStats.cost += job.cost;
          const duration = job.completedAt - job.startedAt;
          providerStats.avgLatency = providerStats.jobs === 1
            ? duration
            : (providerStats.avgLatency * (providerStats.jobs - 1) + duration) / providerStats.jobs;
        }

        if (attempt > 0) {
          console.log(`[orchestrator] Job ${job.id} succeeded on fallback provider: ${currentProvider.name} (attempt ${attempt + 1})`);
        }

        this.emit('job:completed', job);
        return;

      } catch (error) {
        // Record the failure on this provider
        currentProvider.recordFailure(error);
        triedProviders.push(currentProvider.name);

        const providerStats = this.stats.providerStats[currentProvider.name];
        if (providerStats) {
          providerStats.failures++;
        }

        this.emit('provider:failure', currentProvider.name, error);

        console.warn(`[orchestrator] Job ${job.id} failed on ${currentProvider.name}: ${error.message}`);

        // Try to find a fallback provider (excluding already-tried ones)
        if (attempt < maxFallbacks) {
          const fallbacks = this.selectRankedProviders(job.task, triedProviders);
          if (fallbacks.length > 0) {
            currentProvider = fallbacks[0];
            console.log(`[orchestrator] Falling back to ${currentProvider.name} for job ${job.id} (attempt ${attempt + 2})`);
            continue;
          }
        }

        // No more fallbacks available - final failure
        job.status = 'failed';
        job.completedAt = Date.now();
        job.error = `All providers failed. Last error (${currentProvider.name}): ${error.message}. Tried: [${triedProviders.join(', ')}]`;

        this.stats.failedJobs++;

        this.emit('job:failed', job);
        return;
      }
    }
  }

  /**
   * Get cost statistics
   */
  async getCosts(options = {}) {
    const { startDate, endDate } = options;

    // Filter jobs by date range if specified
    let filteredJobs = Array.from(this.jobs.values());

    if (startDate || endDate) {
      const start = startDate ? new Date(startDate).getTime() : 0;
      const end = endDate ? new Date(endDate).getTime() : Date.now();

      filteredJobs = filteredJobs.filter(job =>
        job.submittedAt >= start && job.submittedAt <= end
      );
    }

    const breakdown = {};
    let total = 0;

    for (const job of filteredJobs) {
      if (job.provider && job.cost > 0) {
        breakdown[job.provider] = (breakdown[job.provider] || 0) + job.cost;
        total += job.cost;
      }
    }

    return {
      total: parseFloat(total.toFixed(4)),
      breakdown,
      jobs: filteredJobs.length
    };
  }

  /**
   * Get overall statistics
   */
  getStats() {
    return {
      ...this.stats,
      providers: Array.from(this.providers.keys()),
      avgCostPerJob: this.stats.completedJobs > 0
        ? this.stats.totalCost / this.stats.completedJobs
        : 0
    };
  }

  /**
   * List all jobs
   */
  listJobs(options = {}) {
    const { status, provider, limit = 50 } = options;

    let jobs = Array.from(this.jobs.values());

    if (status) {
      jobs = jobs.filter(j => j.status === status);
    }

    if (provider) {
      jobs = jobs.filter(j => j.provider === provider);
    }

    jobs.sort((a, b) => b.submittedAt - a.submittedAt);

    return jobs.slice(0, limit);
  }

  /**
   * Generate unique job ID
   */
  generateJobId() {
    return `job_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Shutdown orchestrator
   */
  async shutdown() {
    console.log('Shutting down orchestrator...');

    // Wait for pending jobs
    const pendingJobs = this.listJobs({ status: 'running' });
    if (pendingJobs.length > 0) {
      console.log(`Waiting for ${pendingJobs.length} running jobs...`);
      await Promise.all(
        pendingJobs.map(job => this.waitFor(job.id).catch(() => {}))
      );
    }

    // Cleanup providers
    for (const provider of this.providers.values()) {
      if (provider.cleanup) {
        await provider.cleanup();
      }
    }

    console.log('Orchestrator shutdown complete');
  }
}

module.exports = Orchestrator;
