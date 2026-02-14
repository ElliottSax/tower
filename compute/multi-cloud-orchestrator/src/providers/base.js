/**
 * Base Provider Class
 *
 * All cloud providers extend this base class
 */

class BaseProvider {
  constructor(config = {}) {
    this.config = config;
    this.name = 'base';
    this.latency = 'medium';
    this.available = true;
    this.taskScores = {};

    // Track consecutive failures for circuit-breaker pattern
    this.consecutiveFailures = 0;
    this.maxConsecutiveFailures = 3;
    this.unavailableUntil = 0; // timestamp when provider becomes available again
    this.cooldownMs = 60000; // 1 minute cooldown after max failures
  }

  /**
   * Check if provider is available
   */
  isAvailable() {
    if (!this.available) {
      return false;
    }

    // Check if we're in a cooldown period from repeated failures
    if (this.unavailableUntil > 0) {
      if (Date.now() < this.unavailableUntil) {
        return false;
      }
      // Cooldown expired, reset and allow retry
      this.unavailableUntil = 0;
      this.consecutiveFailures = 0;
    }

    return true;
  }

  /**
   * Record a successful execution (resets failure counter)
   */
  recordSuccess() {
    this.consecutiveFailures = 0;
    this.unavailableUntil = 0;
  }

  /**
   * Record a failed execution; triggers cooldown after repeated failures
   */
  recordFailure(error) {
    this.consecutiveFailures++;

    // Check for fatal errors that should immediately disable the provider
    const isFatal = this.isFatalError(error);
    if (isFatal) {
      this.unavailableUntil = Date.now() + this.cooldownMs * 5; // longer cooldown for fatal errors
      console.warn(`[${this.name}] Fatal error, disabled for ${this.cooldownMs * 5}ms: ${error.message}`);
      return;
    }

    if (this.consecutiveFailures >= this.maxConsecutiveFailures) {
      this.unavailableUntil = Date.now() + this.cooldownMs;
      console.warn(`[${this.name}] ${this.consecutiveFailures} consecutive failures, disabled for ${this.cooldownMs}ms`);
    }
  }

  /**
   * Check if an error is fatal (credits exhausted, auth invalid, etc.)
   */
  isFatalError(error) {
    const message = (error.message || '').toLowerCase();
    return (
      error.statusCode === 401 ||
      error.statusCode === 402 ||
      error.statusCode === 403 ||
      message.includes('api key') ||
      message.includes('unauthorized') ||
      message.includes('invalid key') ||
      message.includes('credits') ||
      message.includes('insufficient') ||
      message.includes('payment required') ||
      message.includes('quota exceeded')
    );
  }

  /**
   * Get compatibility score for task type (0-100)
   */
  getTaskScore(taskType) {
    return this.taskScores[taskType] || 50;
  }

  /**
   * Estimate cost for task
   */
  estimateCost(task) {
    return 0.001; // Default: $0.001 per task
  }

  /**
   * Execute task - must be implemented by subclasses
   */
  async execute(task) {
    throw new Error('execute() must be implemented by provider');
  }

  /**
   * Safely parse JSON from a fetch response.
   * Returns the parsed object, or a fallback object if parsing fails.
   */
  async safeParseJSON(response) {
    try {
      const text = await response.text();
      return JSON.parse(text);
    } catch (e) {
      return { error: { message: `HTTP ${response.status}: ${response.statusText}` } };
    }
  }

  /**
   * Extract text from a standard OpenAI-compatible chat completion response.
   * Throws a clear error if the response shape is unexpected.
   */
  extractChatText(result) {
    if (!result.choices || !Array.isArray(result.choices) || result.choices.length === 0) {
      // Check if the result is actually an error object
      if (result.error) {
        throw new Error(result.error.message || 'API returned an error');
      }
      throw new Error('API returned no choices in response');
    }

    const choice = result.choices[0];
    if (!choice.message || typeof choice.message.content !== 'string') {
      throw new Error('API returned unexpected choice format (missing message.content)');
    }

    return choice.message.content;
  }

  /**
   * Build a provider error with status code metadata for circuit-breaker decisions.
   */
  buildError(message, statusCode) {
    const err = new Error(message);
    err.statusCode = statusCode;
    return err;
  }

  /**
   * Cleanup resources
   */
  async cleanup() {
    // Override in subclasses if needed
  }
}

module.exports = BaseProvider;
