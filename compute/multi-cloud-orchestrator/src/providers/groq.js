/**
 * Groq AI Provider - Ultra-fast inference
 *
 * Leverages Groq's LPU (Language Processing Unit) for blazing fast AI inference
 * Best for: Real-time chat, low-latency applications, streaming responses
 */

const BaseProvider = require('./base');

class GroqProvider extends BaseProvider {
  constructor(config = {}) {
    super(config);
    this.name = 'groq';
    this.latency = 'ultra-low'; // Groq is exceptionally fast

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

    this.apiKey = config.apiKey || process.env.GROQ_API_KEY || '';
    this.apiUrl = 'https://api.groq.com/openai/v1';

    // Available models (as of 2026)
    this.models = {
      'llama-3.3-70b-versatile': { tokens: 8192, speed: 'ultra-fast' },
      'llama-3.2-90b-text-preview': { tokens: 8192, speed: 'ultra-fast' },
      'mixtral-8x7b-32768': { tokens: 32768, speed: 'ultra-fast', deprecated: true }
    };

    this.defaultModel = config.model || 'llama-3.3-70b-versatile';
  }

  async execute(task) {
    const { type, payload } = task;

    if (!this.apiKey) {
      throw this.buildError('Groq API key not configured', 401);
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

    // Make request to Groq API
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
        top_p: payload.topP || 1,
        stream: false
      })
    });

    if (!response.ok) {
      const errorBody = await this.safeParseJSON(response);
      const errorMsg = errorBody.error?.message || response.statusText;

      if (response.status === 429) {
        const retryAfter = response.headers.get('retry-after');
        throw this.buildError(`Groq rate limited: ${errorMsg}${retryAfter ? ` (retry after ${retryAfter}s)` : ''}`, 429);
      }
      if (response.status === 401 || response.status === 403) {
        throw this.buildError(`Groq auth error: ${errorMsg}`, response.status);
      }
      throw this.buildError(`Groq API error: ${errorMsg}`, response.status);
    }

    const result = await this.safeParseJSON(response);
    const text = this.extractChatText(result);

    return {
      text,
      model: result.model,
      usage: result.usage,
      time: result.usage?.total_time,
      speed: (result.usage?.total_tokens && result.usage?.total_time)
        ? Math.round(result.usage.total_tokens / result.usage.total_time)
        : null,
      provider: 'groq'
    };
  }

  estimateCost(task) {
    // Groq has generous free tier
    // Pro pricing is very competitive
    return 0; // Free tier
  }
}

module.exports = GroqProvider;
