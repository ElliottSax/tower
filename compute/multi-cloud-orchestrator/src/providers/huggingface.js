/**
 * Hugging Face Inference Providers API
 *
 * Uses the OpenAI-compatible router endpoint (router.huggingface.co/v1).
 * The old api-inference.huggingface.co and router.huggingface.co/models/
 * endpoints are deprecated for most large LLMs.
 *
 * Best for: ML inference, text generation, summarization, code generation
 */

const BaseProvider = require('./base');

class HuggingFaceProvider extends BaseProvider {
  constructor(config = {}) {
    super(config);
    this.name = 'huggingface';
    this.latency = 'medium';

    // Task compatibility scores (0-100)
    this.taskScores = {
      'text-generation': 100,
      'text-classification': 95,
      'sentiment-analysis': 95,
      'summarization': 100,
      'translation': 95,
      'question-answering': 100,
      'text-to-image': 90,
      'image-classification': 85,
      'object-detection': 85,
      'speech-to-text': 80,
      'embeddings': 100,
      'feature-extraction': 100,
      'fill-mask': 85,
      'token-classification': 85,
      'zero-shot-classification': 90,
      'text-analysis': 85,
      'code-generation': 100,
      'hash': 20,
      'data-transform': 30
    };

    this.apiKey = config.apiKey || process.env.HUGGINGFACE_API_KEY || '';

    // OpenAI-compatible chat completions endpoint (current recommended API)
    this.chatApiUrl = 'https://router.huggingface.co/v1/chat/completions';

    // Default models for each task - models confirmed to work via Inference Providers API
    this.defaultModels = config.models || {
      'text-generation': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'text-classification': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'sentiment-analysis': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'summarization': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'translation': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'question-answering': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'embeddings': 'sentence-transformers/all-MiniLM-L6-v2',
      'feature-extraction': 'sentence-transformers/all-MiniLM-L6-v2',
      'code-generation': 'Qwen/Qwen2.5-Coder-32B-Instruct',
      'text-to-image': 'stabilityai/stable-diffusion-2',
      'image-classification': 'google/vit-base-patch16-224',
      'fill-mask': 'bert-base-uncased',
      'token-classification': 'dslim/bert-base-NER',
      'zero-shot-classification': 'facebook/bart-large-mnli'
    };

    // Tasks that use the OpenAI-compatible chat/completions endpoint
    this.chatTasks = new Set([
      'text-generation',
      'text-classification',
      'sentiment-analysis',
      'summarization',
      'translation',
      'question-answering',
      'code-generation',
      'text-analysis',
      'zero-shot-classification'
    ]);
  }

  async execute(task) {
    const { type, payload } = task;

    if (!this.apiKey) {
      throw this.buildError('Hugging Face API key not configured', 401);
    }

    // Get model for this task
    const model = payload.model || this.defaultModels[type];

    if (!model) {
      throw new Error(`No model configured for task type: ${type}`);
    }

    // Use chat completions API for text/LLM tasks, legacy API for specialized tasks
    if (this.chatTasks.has(type)) {
      return this._executeChatCompletion(type, payload, model);
    } else {
      return this._executeLegacyInference(type, payload, model);
    }
  }

  /**
   * Execute via OpenAI-compatible chat/completions endpoint.
   * This is the current recommended API for HuggingFace Inference Providers.
   */
  async _executeChatCompletion(type, payload, model) {
    // Build the user message based on task type
    const userMessage = this._buildChatMessage(type, payload);

    const requestBody = {
      model: model,
      messages: [
        { role: 'user', content: userMessage }
      ],
      max_tokens: payload.maxTokens || payload.maxLength || 1024,
      temperature: payload.temperature || 0.7,
      top_p: payload.topP || 0.9,
      stream: false
    };

    const response = await fetch(this.chatApiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
      let errorMsg;
      try {
        const error = await response.json();
        errorMsg = error.error?.message || error.error || response.statusText;
      } catch {
        errorMsg = response.statusText;
      }

      // Handle model loading (503)
      if (response.status === 503) {
        throw this.buildError(`Hugging Face model loading, retry later: ${errorMsg}`, 503);
      }

      if (response.status === 401 || response.status === 403) {
        throw this.buildError(`Hugging Face auth error: ${errorMsg}`, response.status);
      }

      if (response.status === 429) {
        throw this.buildError(`Hugging Face rate limited: ${errorMsg}`, 429);
      }

      throw this.buildError(`Hugging Face API error (${response.status}): ${errorMsg}`, response.status);
    }

    const result = await this.safeParseJSON(response);

    // Parse OpenAI-compatible response format
    const content = result.choices?.[0]?.message?.content || '';
    const usage = result.usage || {};

    return {
      result: content,
      model,
      provider: 'huggingface',
      usage: {
        promptTokens: usage.prompt_tokens,
        completionTokens: usage.completion_tokens,
        totalTokens: usage.total_tokens
      }
    };
  }

  /**
   * Build the chat message content based on task type.
   * Wraps task-specific inputs into a natural language prompt for the chat API.
   */
  _buildChatMessage(type, payload) {
    switch (type) {
      case 'text-generation':
        return payload.text || payload.prompt;

      case 'text-classification':
        return `Classify the following text into a category. Return only the category label.\n\nText: ${payload.text}`;

      case 'sentiment-analysis':
        return `Analyze the sentiment of the following text. Return one of: POSITIVE, NEGATIVE, or NEUTRAL, followed by a confidence score.\n\nText: ${payload.text}`;

      case 'summarization':
        return `Summarize the following text in ${payload.maxLength || 130} words or fewer:\n\n${payload.text}`;

      case 'translation':
        return `Translate the following text to ${payload.targetLanguage || 'English'}:\n\n${payload.text}`;

      case 'question-answering':
        return `Answer the following question based on the context provided.\n\nContext: ${payload.context}\n\nQuestion: ${payload.question}`;

      case 'code-generation':
        return payload.prompt || payload.text;

      case 'zero-shot-classification':
        return `Classify the following text into one of these categories: ${(payload.labels || []).join(', ')}.\nReturn the category and confidence score.\n\nText: ${payload.text}`;

      case 'text-analysis':
        return `Analyze the following text and provide insights:\n\n${payload.text}`;

      default:
        return payload.text || payload.prompt || payload.inputs || '';
    }
  }

  /**
   * Execute via legacy per-model inference endpoint.
   * Used for specialized tasks like embeddings, image classification, etc.
   * that don't fit the chat completions format.
   */
  async _executeLegacyInference(type, payload, model) {
    const url = `https://router.huggingface.co/models/${model}`;

    let requestBody;

    switch (type) {
      case 'embeddings':
      case 'feature-extraction':
        requestBody = {
          inputs: payload.text || payload.texts
        };
        break;

      case 'text-to-image':
        requestBody = {
          inputs: payload.prompt,
          parameters: {
            width: payload.width || 512,
            height: payload.height || 512,
            num_inference_steps: payload.steps || 50
          }
        };
        break;

      case 'image-classification':
        requestBody = {
          inputs: payload.image
        };
        break;

      case 'fill-mask':
        requestBody = {
          inputs: payload.text
        };
        break;

      case 'token-classification':
        requestBody = {
          inputs: payload.text
        };
        break;

      default:
        requestBody = { inputs: payload.inputs || payload.text };
    }

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
      let errorMsg;
      try {
        const error = await response.json();
        errorMsg = error.error || response.statusText;
      } catch {
        errorMsg = response.statusText;
      }
      if (response.status === 401 || response.status === 403) {
        throw this.buildError(`Hugging Face auth error: ${errorMsg}`, response.status);
      }
      if (response.status === 429) {
        throw this.buildError(`Hugging Face rate limited: ${errorMsg}`, 429);
      }
      throw this.buildError(`Hugging Face API error (${response.status}): ${errorMsg}`, response.status);
    }

    // Handle different response types
    const contentType = response.headers.get('content-type');

    if (contentType && contentType.includes('image')) {
      const buffer = await response.arrayBuffer();
      return {
        image: Buffer.from(buffer).toString('base64'),
        model,
        provider: 'huggingface'
      };
    } else {
      const result = await response.json();
      return {
        result,
        model,
        provider: 'huggingface'
      };
    }
  }

  estimateCost(task) {
    // HuggingFace Inference Providers pricing (approximate)
    // Free tier available; Pro tier for higher rate limits

    const costPerCall = {
      'text-generation': 0.00001,
      'text-classification': 0.000005,
      'sentiment-analysis': 0.000005,
      'summarization': 0.00001,
      'translation': 0.00001,
      'question-answering': 0.000005,
      'code-generation': 0.00002,
      'text-to-image': 0.0001,
      'image-classification': 0.00002,
      'embeddings': 0.000005,
      'feature-extraction': 0.000005
    };

    return costPerCall[task.type] || 0.00001;
  }
}

module.exports = HuggingFaceProvider;
