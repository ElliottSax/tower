/**
 * Together AI Provider
 *
 * Multi-model AI platform with wide model selection
 * Best for: Various AI tasks, flexible model choices, cost-effective inference
 */

const BaseProvider = require('./base');

class TogetherProvider extends BaseProvider {
  constructor(config = {}) {
    super(config);
    this.name = 'together';
    this.latency = 'low';

    // Task compatibility scores (0-100)
    this.taskScores = {
      'chat': 100,
      'text-generation': 100,
      'code-generation': 95,
      'summarization': 90,
      'translation': 85,
      'question-answering': 95,
      'reasoning': 90,
      'conversation': 100,
      'image-generation': 85,
      'embeddings': 90,
      'hash': 10,
      'data-transform': 20
    };

    this.apiKey = config.apiKey || process.env.TOGETHER_API_KEY || '';
    this.apiUrl = 'https://api.together.xyz/v1';

    // Popular models
    this.models = {
      'meta-llama/Llama-3.2-3B-Instruct-Turbo': { tokens: 8192, speed: 'fast' },
      'meta-llama/Llama-3.3-70B-Instruct-Turbo': { tokens: 8192, speed: 'medium' },
      'mistralai/Mixtral-8x7B-Instruct-v0.1': { tokens: 32768, speed: 'medium' }
    };

    this.defaultModel = config.model || 'meta-llama/Llama-3.2-3B-Instruct-Turbo';
    this.maxRetries = 1;
    this.retryDelayMs = 2000;
  }

  async execute(task) {
    const { type, payload } = task;

    if (!this.apiKey) {
      throw this.buildError('Together AI API key not configured', 401);
    }

    const model = payload.model || this.defaultModel;

    // Prepare messages
    let messages;
    if (payload.messages) {
      messages = payload.messages;
    } else if (payload.prompt || payload.text) {
      messages = [{ role: 'user', content: payload.prompt || payload.text }];
    } else {
      throw new Error('No prompt or messages provided');
    }

    let lastError = null;

    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      if (attempt > 0) {
        await new Promise(resolve => setTimeout(resolve, this.retryDelayMs * attempt));
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
          top_p: payload.topP || 0.9
        })
      });

      if (!response.ok) {
        const errorBody = await this.safeParseJSON(response);
        const errorMsg = errorBody.error?.message || response.statusText;

        // Credit exhaustion - immediately fail, no retry
        if (response.status === 402) {
          throw this.buildError(`Together AI credits exhausted: ${errorMsg}. Add credits at https://api.together.xyz/settings/billing`, 402);
        }

        // Auth errors - immediately fail
        if (response.status === 401 || response.status === 403) {
          throw this.buildError(`Together AI auth error: ${errorMsg}`, response.status);
        }

        // Rate limiting - wait and retry
        if (response.status === 429) {
          const retryAfter = response.headers.get('retry-after');
          const waitMs = retryAfter ? parseInt(retryAfter, 10) * 1000 : this.retryDelayMs * (attempt + 1);

          if (attempt < this.maxRetries && waitMs < 30000) {
            console.warn(`[together] Rate limited, waiting ${waitMs}ms before retry...`);
            await new Promise(resolve => setTimeout(resolve, waitMs));
            continue;
          }
          throw this.buildError(`Together AI rate limited: ${errorMsg}`, 429);
        }

        // Server errors - retry
        if (response.status >= 500 && attempt < this.maxRetries) {
          lastError = this.buildError(`Together AI server error: ${errorMsg}`, response.status);
          console.warn(`[together] Server error ${response.status}, retrying (${attempt + 1}/${this.maxRetries})...`);
          continue;
        }

        throw this.buildError(`Together AI error: ${errorMsg}`, response.status);
      }

      const result = await this.safeParseJSON(response);
      const text = this.extractChatText(result);

      return {
        text,
        model: result.model,
        usage: result.usage,
        provider: 'together'
      };
    }

    throw lastError || new Error('Together AI: max retries exceeded');
  }

  estimateCost(task) {
    // Together AI pricing is competitive
    // Approximate: $0.20 per 1M tokens for input, $0.80 per 1M for output
    const avgTokens = 500;
    return (avgTokens / 1000000) * 0.50; // Average cost
  }
}

module.exports = TogetherProvider;
