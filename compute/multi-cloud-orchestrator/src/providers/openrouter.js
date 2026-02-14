/**
 * OpenRouter Provider
 *
 * Access to 100+ AI models through a single API
 * Best for: Model variety, fallback options, accessing latest models
 */

const BaseProvider = require('./base');

class OpenRouterProvider extends BaseProvider {
  constructor(config = {}) {
    super(config);
    this.name = 'openrouter';
    this.latency = 'medium';

    // Task compatibility scores (0-100)
    this.taskScores = {
      'chat': 100,
      'text-generation': 100,
      'code-generation': 95,
      'summarization': 90,
      'translation': 85,
      'question-answering': 95,
      'reasoning': 95,
      'conversation': 100,
      'hash': 10,
      'data-transform': 20
    };

    this.apiKey = config.apiKey || process.env.OPENROUTER_API_KEY || '';
    this.apiUrl = 'https://openrouter.ai/api/v1';

    // Available models (mix of free and paid)
    this.models = {
      // Paid models (working)
      'meta-llama/llama-3.1-8b-instruct': {
        tokens: 8192,
        speed: 'fast',
        cost: 0.00000133, // per request (tested)
        free: false
      },
      'openai/gpt-3.5-turbo': {
        tokens: 16385,
        speed: 'fast',
        cost: 0.0000175, // per request (tested)
        free: false
      },
      'meta-llama/llama-3.1-70b-instruct': {
        tokens: 8192,
        speed: 'medium',
        cost: 0.00001, // estimated
        free: false
      },
      'anthropic/claude-3-haiku': {
        tokens: 200000,
        speed: 'fast',
        cost: 0.00005, // estimated
        free: false
      },
      // Free models (often rate-limited)
      'meta-llama/llama-3.2-3b-instruct:free': {
        tokens: 8192,
        speed: 'medium',
        cost: 0,
        free: true,
        note: 'Often rate-limited'
      }
    };

    this.defaultModel = config.model || 'meta-llama/llama-3.1-8b-instruct';

    // Rate limiting state
    this.rateLimitResetTime = 0; // timestamp when rate limit resets
    this.maxRetries = 2;
    this.retryDelayMs = 2000;
  }

  async execute(task) {
    const { type, payload } = task;

    if (!this.apiKey) {
      throw this.buildError('OpenRouter API key not configured', 401);
    }

    const requestedModel = payload.model || this.defaultModel;

    // Prepare messages
    let messages;
    if (payload.messages) {
      messages = payload.messages;
    } else if (payload.prompt || payload.text) {
      messages = [{ role: 'user', content: payload.prompt || payload.text }];
    } else {
      throw new Error('No prompt or messages provided');
    }

    // Try the requested model, then fall back to paid models if free model is rate-limited
    const modelsToTry = this._getModelFallbackChain(requestedModel);

    let lastError = null;

    for (const model of modelsToTry) {
      try {
        return await this._makeRequest(model, messages, payload);
      } catch (error) {
        lastError = error;

        // If rate-limited on a free model, try the next model in the chain
        if (error.statusCode === 429 && this._isModelFree(model)) {
          console.warn(`[openrouter] Free model ${model} rate-limited, trying next model...`);
          continue;
        }

        // For non-rate-limit errors, or rate-limit on paid models, don't retry other models
        throw error;
      }
    }

    // All models in the chain failed
    throw lastError || new Error('OpenRouter: all model fallbacks exhausted');
  }

  /**
   * Make a single request to the OpenRouter API with retry on transient errors.
   */
  async _makeRequest(model, messages, payload) {
    let lastError = null;

    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      if (attempt > 0) {
        // Exponential backoff: 2s, 4s
        const delay = this.retryDelayMs * Math.pow(2, attempt - 1);
        await new Promise(resolve => setTimeout(resolve, delay));
      }

      const response = await fetch(`${this.apiUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model,
          messages,
          max_tokens: payload.maxTokens || 2000,
          temperature: payload.temperature || 0.7,
          top_p: payload.topP || 1
        })
      });

      if (!response.ok) {
        const errorBody = await this.safeParseJSON(response);
        const errorMsg = errorBody.error?.message || response.statusText;

        // Parse rate limit headers if present
        const retryAfter = response.headers.get('retry-after');
        const rateLimitReset = response.headers.get('x-ratelimit-reset');

        if (response.status === 429) {
          // Rate limited - check if we should wait and retry
          const waitMs = retryAfter
            ? parseInt(retryAfter, 10) * 1000
            : (rateLimitReset ? (parseInt(rateLimitReset, 10) * 1000 - Date.now()) : this.retryDelayMs);

          // Only retry with wait if the wait is reasonable (< 30s) and not a free model
          if (waitMs > 0 && waitMs < 30000 && !this._isModelFree(model) && attempt < this.maxRetries) {
            console.warn(`[openrouter] Rate limited on ${model}, waiting ${waitMs}ms before retry...`);
            await new Promise(resolve => setTimeout(resolve, waitMs));
            continue;
          }

          lastError = this.buildError(`OpenRouter rate limited: ${errorMsg}`, 429);
          throw lastError;
        }

        if (response.status === 402) {
          throw this.buildError(`OpenRouter credits exhausted: ${errorMsg}`, 402);
        }

        if (response.status === 401 || response.status === 403) {
          throw this.buildError(`OpenRouter auth error: ${errorMsg}`, response.status);
        }

        // Server errors (500, 502, 503) - retry
        if (response.status >= 500 && attempt < this.maxRetries) {
          lastError = this.buildError(`OpenRouter server error: ${errorMsg}`, response.status);
          console.warn(`[openrouter] Server error ${response.status}, retrying (${attempt + 1}/${this.maxRetries})...`);
          continue;
        }

        throw this.buildError(`OpenRouter API error: ${errorMsg}`, response.status);
      }

      const result = await this.safeParseJSON(response);
      const text = this.extractChatText(result);

      return {
        text,
        model: result.model,
        upstreamProvider: result.provider || 'unknown',
        usage: result.usage,
        cost: result.usage?.cost || 0,
        provider: 'openrouter'
      };
    }

    throw lastError || new Error('OpenRouter: max retries exceeded');
  }

  /**
   * Build a fallback chain of models to try. If a free model is requested,
   * include the default paid model as a fallback.
   */
  _getModelFallbackChain(requestedModel) {
    const chain = [requestedModel];

    if (this._isModelFree(requestedModel)) {
      // Add the default paid model as fallback
      if (this.defaultModel !== requestedModel && !this._isModelFree(this.defaultModel)) {
        chain.push(this.defaultModel);
      }
      // Add llama-3.1-8b as a cheap paid fallback if not already in chain
      const cheapFallback = 'meta-llama/llama-3.1-8b-instruct';
      if (!chain.includes(cheapFallback)) {
        chain.push(cheapFallback);
      }
    }

    return chain;
  }

  /**
   * Check if a model ID is a free model.
   */
  _isModelFree(model) {
    const modelInfo = this.models[model];
    if (modelInfo) {
      return modelInfo.free === true;
    }
    // Convention: free models end with ":free"
    return model.endsWith(':free');
  }

  estimateCost(task) {
    // OpenRouter provides actual cost in response
    // Estimate based on model
    const model = task.payload?.model || this.defaultModel;
    const modelInfo = this.models[model];

    if (modelInfo && modelInfo.cost) {
      return modelInfo.cost;
    }

    // Default estimate
    return 0.00001;
  }
}

module.exports = OpenRouterProvider;
