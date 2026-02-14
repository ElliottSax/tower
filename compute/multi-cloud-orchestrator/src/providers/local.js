/**
 * Local Provider
 *
 * Fallback provider that executes tasks locally
 * Best for: Development, testing, when cloud is unavailable
 */

const BaseProvider = require('./base');
const crypto = require('crypto');

class LocalProvider extends BaseProvider {
  constructor(config = {}) {
    super(config);
    this.name = 'local';
    this.latency = 'low';

    // Local provider can handle all tasks, but with low priority
    this.taskScores = {
      'hash': 70,
      'base64': 70,
      'json-transform': 70,
      'text-analysis': 60,
      'data-transform': 60,
      'heavy-compute': 40, // Avoid heavy compute locally
      'image-resize': 50,
      'video-transcode': 20 // Really avoid video locally
    };
  }

  async execute(task) {
    const { type, payload } = task;

    console.log(`[Local] Executing ${type} on local machine`);

    switch (type) {
      case 'hash':
        return this.computeHash(payload);
      case 'base64':
        return this.base64Operation(payload);
      case 'json-transform':
        return this.jsonTransform(payload);
      case 'text-analysis':
        return this.analyzeText(payload);
      case 'data-transform':
        return this.transformData(payload);
      case 'heavy-compute':
        return this.heavyCompute(payload);
      default:
        throw new Error(`Unsupported task type: ${type}`);
    }
  }

  async computeHash(payload) {
    const text = payload.text || '';
    const hash = crypto.createHash('sha256').update(text).digest('hex');

    return {
      hash,
      length: text.length,
      provider: 'local'
    };
  }

  async base64Operation(payload) {
    const { operation, input } = payload;
    let result;

    if (operation === 'encode') {
      result = Buffer.from(input).toString('base64');
    } else {
      result = Buffer.from(input, 'base64').toString('utf8');
    }

    return { result, operation, provider: 'local' };
  }

  async jsonTransform(payload) {
    const { data, transform } = payload;
    let result;

    if (transform === 'stringify') {
      result = JSON.stringify(data, null, 2);
    } else if (transform === 'flatten') {
      result = this.flattenObject(data);
    } else {
      throw new Error(`Unknown transform: ${transform}`);
    }

    return { result, provider: 'local' };
  }

  async analyzeText(payload) {
    const text = payload.text || '';
    const words = text.split(/\s+/);
    const sentences = text.split(/[.!?]+/);

    return {
      length: text.length,
      words: words.length,
      sentences: sentences.length,
      avgWordLength: words.reduce((sum, w) => sum + w.length, 0) / words.length,
      uppercaseRatio: (text.match(/[A-Z]/g) || []).length / text.length,
      provider: 'local'
    };
  }

  async transformData(payload) {
    const { data, operation } = payload;
    let result;

    switch (operation) {
      case 'sum':
        result = data.reduce((sum, n) => sum + n, 0);
        break;
      case 'average':
        result = data.reduce((sum, n) => sum + n, 0) / data.length;
        break;
      case 'sort':
        result = [...data].sort((a, b) => a - b);
        break;
      case 'dedupe':
        result = [...new Set(data)];
        break;
      default:
        throw new Error(`Unknown operation: ${operation}`);
    }

    return { result, provider: 'local' };
  }

  async heavyCompute(payload) {
    const iterations = Math.min(payload.iterations || 100000, 1000000);
    let result = 0;

    for (let i = 0; i < iterations; i++) {
      result += Math.sqrt(i) * Math.sin(i);
    }

    return {
      result,
      iterations,
      provider: 'local',
      warning: 'Heavy compute executed locally - consider using cloud provider'
    };
  }

  flattenObject(obj, prefix = '') {
    const flattened = {};

    for (const [key, value] of Object.entries(obj)) {
      const newKey = prefix ? `${prefix}.${key}` : key;

      if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        Object.assign(flattened, this.flattenObject(value, newKey));
      } else {
        flattened[newKey] = value;
      }
    }

    return flattened;
  }

  estimateCost(task) {
    // Local execution has no cloud cost, but has opportunity cost
    return 0;
  }
}

module.exports = LocalProvider;
