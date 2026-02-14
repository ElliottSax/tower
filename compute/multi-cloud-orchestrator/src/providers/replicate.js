/**
 * Replicate Provider
 *
 * ML model hosting and inference platform with 1000+ models
 * Best for: Image generation, video processing, specialized ML tasks
 */

const BaseProvider = require('./base');

class ReplicateProvider extends BaseProvider {
  constructor(config = {}) {
    super(config);
    this.name = 'replicate';
    this.latency = 'medium'; // Depends on model

    // Task compatibility scores (0-100)
    this.taskScores = {
      'image-generation': 100,
      'text-to-image': 100,
      'image-to-image': 100,
      'video-generation': 95,
      'audio-generation': 90,
      'chat': 85,
      'text-generation': 85,
      'code-generation': 80,
      'upscaling': 100,
      'inpainting': 95,
      'hash': 10,
      'data-transform': 20
    };

    this.apiKey = config.apiKey || process.env.REPLICATE_API_KEY || '';
    this.apiUrl = 'https://api.replicate.com/v1';

    // Popular models
    this.models = {
      'stability-ai/sdxl': 'text-to-image',
      'meta/llama-2-70b-chat': 'chat',
      'stability-ai/stable-video-diffusion': 'video-generation'
    };
  }

  async execute(task) {
    const { type, payload } = task;

    if (!this.apiKey) {
      throw this.buildError('Replicate API key not configured', 401);
    }

    // For now, implement list models as proof of concept
    if (type === 'list-models' || !payload.model) {
      const response = await fetch(`${this.apiUrl}/models`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`
        }
      });

      if (!response.ok) {
        const errorBody = await this.safeParseJSON(response);
        const errorMsg = errorBody.detail || errorBody.error?.message || response.statusText;
        if (response.status === 401 || response.status === 403) {
          throw this.buildError(`Replicate auth error: ${errorMsg}`, response.status);
        }
        throw this.buildError(`Replicate API error: ${errorMsg}`, response.status);
      }

      const result = await this.safeParseJSON(response);
      const results = result.results || [];
      return {
        models: results.map(m => `${m.owner}/${m.name}`),
        count: results.length,
        provider: 'replicate'
      };
    }

    // For actual model execution, need to implement prediction API
    const response = await fetch(`${this.apiUrl}/predictions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        version: payload.version,
        input: payload.input || {}
      })
    });

    if (!response.ok) {
      const errorBody = await this.safeParseJSON(response);
      const errorMsg = errorBody.detail || errorBody.error?.message || response.statusText;
      if (response.status === 401 || response.status === 403) {
        throw this.buildError(`Replicate auth error: ${errorMsg}`, response.status);
      }
      if (response.status === 402) {
        throw this.buildError(`Replicate credits exhausted: ${errorMsg}`, 402);
      }
      throw this.buildError(`Replicate API error: ${errorMsg}`, response.status);
    }

    const result = await this.safeParseJSON(response);
    return {
      id: result.id,
      status: result.status,
      output: result.output,
      provider: 'replicate'
    };
  }

  estimateCost(task) {
    // Replicate is pay-per-use, varies by model
    // Image generation: ~$0.002-0.01 per image
    return 0.005; // Average estimate
  }
}

module.exports = ReplicateProvider;
