/**
 * DeepSeek AI Provider
 *
 * Uses DeepSeek's AI models for code generation, reasoning, and chat
 * Best for: Code generation, technical Q&A, reasoning tasks, AI assistance
 */

const BaseProvider = require('./base');

class DeepSeekProvider extends BaseProvider {
  constructor(config = {}) {
    super(config);
    this.name = 'deepseek';
    this.latency = 'medium';

    // Task compatibility scores (0-100)
    this.taskScores = {
      'code-generation': 100,
      'code-completion': 100,
      'code-explanation': 95,
      'code-review': 95,
      'bug-fix': 90,
      'refactoring': 90,
      'text-generation': 85,
      'question-answering': 90,
      'reasoning': 95,
      'chat': 85,
      'summarization': 80,
      'translation': 75,
      'hash': 10,
      'data-transform': 20
    };

    this.apiKey = config.apiKey || process.env.DEEPSEEK_API_KEY || '';
    this.apiUrl = config.apiUrl || 'https://api.deepseek.com/v1';

    // Default models
    this.models = config.models || {
      'code-generation': 'deepseek-coder',
      'code-completion': 'deepseek-coder',
      'reasoning': 'deepseek-chat',
      'chat': 'deepseek-chat'
    };
  }

  async execute(task) {
    const { type, payload } = task;

    if (!this.apiKey) {
      throw this.buildError('DeepSeek API key not configured', 401);
    }

    // Get model for this task
    const model = payload.model || this.models[type] || 'deepseek-chat';

    // Prepare messages based on task type
    let messages;

    switch (type) {
      case 'code-generation':
        messages = [
          {
            role: 'system',
            content: 'You are an expert programmer. Generate clean, efficient, well-documented code.'
          },
          {
            role: 'user',
            content: payload.prompt || payload.text
          }
        ];
        break;

      case 'code-completion':
        messages = [
          {
            role: 'system',
            content: 'Complete the following code.'
          },
          {
            role: 'user',
            content: payload.code || payload.text
          }
        ];
        break;

      case 'code-explanation':
        messages = [
          {
            role: 'system',
            content: 'Explain the following code clearly and concisely.'
          },
          {
            role: 'user',
            content: payload.code || payload.text
          }
        ];
        break;

      case 'code-review':
        messages = [
          {
            role: 'system',
            content: 'Review this code for bugs, performance issues, and best practices.'
          },
          {
            role: 'user',
            content: payload.code || payload.text
          }
        ];
        break;

      case 'bug-fix':
        messages = [
          {
            role: 'system',
            content: 'Identify and fix bugs in the following code.'
          },
          {
            role: 'user',
            content: payload.code || payload.text
          }
        ];
        break;

      case 'refactoring':
        messages = [
          {
            role: 'system',
            content: 'Refactor this code to improve quality, readability, and maintainability.'
          },
          {
            role: 'user',
            content: payload.code || payload.text
          }
        ];
        break;

      case 'reasoning':
      case 'question-answering':
        messages = [
          {
            role: 'system',
            content: 'You are a helpful assistant that provides thoughtful, accurate answers.'
          },
          {
            role: 'user',
            content: payload.question || payload.prompt || payload.text
          }
        ];
        break;

      case 'chat':
        messages = payload.messages || [
          {
            role: 'user',
            content: payload.text || payload.prompt
          }
        ];
        break;

      case 'summarization':
        messages = [
          {
            role: 'system',
            content: 'Summarize the following text concisely.'
          },
          {
            role: 'user',
            content: payload.text
          }
        ];
        break;

      default:
        // Generic prompt
        messages = [
          {
            role: 'user',
            content: payload.prompt || payload.text
          }
        ];
    }

    // Make request to DeepSeek API
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
        top_p: payload.topP || 0.95,
        stream: false
      })
    });

    if (!response.ok) {
      const errorBody = await this.safeParseJSON(response);
      const errorMsg = errorBody.error?.message || response.statusText;

      if (response.status === 429) {
        throw this.buildError(`DeepSeek rate limited: ${errorMsg}`, 429);
      }
      if (response.status === 401 || response.status === 403) {
        throw this.buildError(`DeepSeek auth error: ${errorMsg}`, response.status);
      }
      if (response.status === 402) {
        throw this.buildError(`DeepSeek credits exhausted: ${errorMsg}`, 402);
      }
      throw this.buildError(`DeepSeek API error: ${errorMsg}`, response.status);
    }

    const result = await this.safeParseJSON(response);
    const text = this.extractChatText(result);

    return {
      text,
      model: result.model,
      usage: result.usage,
      provider: 'deepseek',
      timestamp: new Date().toISOString()
    };
  }

  estimateCost(task) {
    // DeepSeek pricing (as of 2024)
    // DeepSeek-Coder: ~$0.14 per 1M tokens
    // DeepSeek-Chat: ~$0.14 per 1M tokens

    const avgTokensPerTask = {
      'code-generation': 500,
      'code-completion': 200,
      'code-explanation': 300,
      'code-review': 400,
      'bug-fix': 300,
      'reasoning': 300,
      'chat': 200,
      'summarization': 150
    };

    const tokens = avgTokensPerTask[task.type] || 250;
    const costPer1MTokens = 0.14;
    const cost = (tokens / 1000000) * costPer1MTokens;

    return cost;
  }
}

module.exports = DeepSeekProvider;
