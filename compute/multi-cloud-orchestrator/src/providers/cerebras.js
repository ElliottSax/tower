/**
 * Cerebras AI Provider
 *
 * Ultra-fast AI inference on custom Wafer-Scale Engine chips
 * Best for: High-throughput AI, low-latency applications, real-time processing
 */

const BaseProvider = require('./base');

class CerebrasProvider extends BaseProvider {
  constructor(config = {}) {
    super(config);
    this.name = 'cerebras';
    this.latency = 'ultra-low';

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
      'hash': 10,
      'data-transform': 20
    };

    this.apiKey = config.apiKey || process.env.CEREBRAS_API_KEY || '';
    this.apiUrl = 'https://api.cerebras.ai/v1';

    // Available models
    this.models = {
      'llama3.1-8b': { tokens: 8192, speed: 'ultra-fast' },
      'llama3.1-70b': { tokens: 8192, speed: 'fast' }
    };

    this.defaultModel = config.model || 'llama3.1-8b';
  }

  async execute(task) {
    const { type, payload } = task;

    if (!this.apiKey) {
      throw this.buildError('Cerebras API key not configured', 401);
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

    // Make request to Cerebras API
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
        temperature: payload.temperature || 0.7
      })
    });

    if (!response.ok) {
      const errorBody = await this.safeParseJSON(response);
      const errorMsg = errorBody.error?.message || response.statusText;

      if (response.status === 429) {
        throw this.buildError(`Cerebras rate limited: ${errorMsg}`, 429);
      }
      if (response.status === 401 || response.status === 403) {
        throw this.buildError(`Cerebras auth error: ${errorMsg}`, response.status);
      }
      if (response.status === 402) {
        throw this.buildError(`Cerebras credits exhausted: ${errorMsg}`, 402);
      }
      throw this.buildError(`Cerebras API error: ${errorMsg}`, response.status);
    }

    const result = await this.safeParseJSON(response);
    const text = this.extractChatText(result);

    return {
      text,
      model: result.model,
      usage: result.usage,
      time: result.time_info?.total_time,
      provider: 'cerebras'
    };
  }

  estimateCost(task) {
    // Cerebras pricing is very competitive
    return 0.00001; // Approximate low cost
  }
}

module.exports = CerebrasProvider;
