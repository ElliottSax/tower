/**
 * Google Cloud Functions for Compute Offloading
 *
 * All functions are exported from this file
 */

const crypto = require('crypto');
const functions = require('@google-cloud/functions-framework');

/**
 * Compute Hash - Generate SHA-256 hash
 */
functions.http('computeHash', async (req, res) => {
  const startTime = Date.now();

  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    const { text = '' } = req.body || {};

    const hash = crypto.createHash('sha256').update(text).digest('hex');
    const duration = Date.now() - startTime;

    res.status(200).json({
      hash,
      length: text.length,
      algorithm: 'sha256',
      duration,
      provider: 'gcp-functions',
      region: process.env.FUNCTION_REGION || 'unknown',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * Analyze Text - Comprehensive text analysis
 */
functions.http('analyzeText', async (req, res) => {
  const startTime = Date.now();

  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    const { text = '' } = req.body || {};

    const words = text.split(/\s+/).filter(w => w.length > 0);
    const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
    const paragraphs = text.split(/\n\n+/).filter(p => p.trim().length > 0);
    const lines = text.split(/\n/).filter(l => l.trim().length > 0);

    const wordLengths = words.map(w => w.length);
    const avgWordLength = wordLengths.reduce((a, b) => a + b, 0) / (words.length || 1);
    const maxWordLength = Math.max(...wordLengths, 0);
    const minWordLength = Math.min(...wordLengths, Infinity);

    const letters = text.match(/[a-zA-Z]/g) || [];
    const digits = text.match(/\d/g) || [];
    const uppercase = text.match(/[A-Z]/g) || [];
    const lowercase = text.match(/[a-z]/g) || [];
    const spaces = text.match(/\s/g) || [];
    const punctuation = text.match(/[.,!?;:]/g) || [];

    const uniqueWords = new Set(words.map(w => w.toLowerCase()));
    const duration = Date.now() - startTime;

    res.status(200).json({
      text: {
        length: text.length,
        words: words.length,
        sentences: sentences.length,
        paragraphs: paragraphs.length,
        lines: lines.length,
        uniqueWords: uniqueWords.size
      },
      words: {
        count: words.length,
        avgLength: parseFloat(avgWordLength.toFixed(2)),
        maxLength: maxWordLength,
        minLength: minWordLength === Infinity ? 0 : minWordLength,
        unique: uniqueWords.size,
        uniqueRatio: parseFloat((uniqueWords.size / (words.length || 1)).toFixed(3))
      },
      characters: {
        total: text.length,
        letters: letters.length,
        digits: digits.length,
        uppercase: uppercase.length,
        lowercase: lowercase.length,
        spaces: spaces.length,
        punctuation: punctuation.length,
        uppercaseRatio: parseFloat((uppercase.length / (letters.length || 1)).toFixed(3))
      },
      readability: {
        avgWordsPerSentence: parseFloat(((words.length || 0) / (sentences.length || 1)).toFixed(2)),
        avgSentencesPerParagraph: parseFloat(((sentences.length || 0) / (paragraphs.length || 1)).toFixed(2))
      },
      meta: {
        duration,
        provider: 'gcp-functions',
        region: process.env.FUNCTION_REGION || 'unknown',
        memoryUsed: process.memoryUsage().heapUsed,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * Transform Data - Array operations
 */
functions.http('transformData', async (req, res) => {
  const startTime = Date.now();

  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    const { data = [], operation = 'sort' } = req.body || {};

    let result;
    let stats = {};

    switch (operation) {
      case 'sum':
        result = data.reduce((sum, n) => sum + Number(n), 0);
        stats.inputSize = data.length;
        break;

      case 'average':
        const sum = data.reduce((sum, n) => sum + Number(n), 0);
        result = sum / (data.length || 1);
        stats.inputSize = data.length;
        stats.sum = sum;
        break;

      case 'median':
        const sorted = [...data].map(Number).sort((a, b) => a - b);
        const mid = Math.floor(sorted.length / 2);
        result = sorted.length % 2 === 0
          ? (sorted[mid - 1] + sorted[mid]) / 2
          : sorted[mid];
        stats.inputSize = data.length;
        break;

      case 'sort':
        result = [...data].sort((a, b) => Number(a) - Number(b));
        stats.inputSize = data.length;
        break;

      case 'reverse':
        result = [...data].reverse();
        stats.inputSize = data.length;
        break;

      case 'dedupe':
        result = [...new Set(data)];
        stats.inputSize = data.length;
        stats.outputSize = result.length;
        stats.duplicatesRemoved = data.length - result.length;
        break;

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }

    const duration = Date.now() - startTime;

    res.status(200).json({
      result,
      operation,
      stats,
      meta: {
        duration,
        provider: 'gcp-functions',
        region: process.env.FUNCTION_REGION || 'unknown',
        memoryUsed: process.memoryUsage().heapUsed,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * Heavy Compute - CPU-intensive calculations
 */
functions.http('heavyCompute', async (req, res) => {
  const startTime = Date.now();

  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    const { iterations = 100000, operation = 'mixed' } = req.body || {};
    const maxIterations = Math.min(Number(iterations), 10000000);

    let result = 0;
    let operations = 0;

    switch (operation) {
      case 'mixed':
        for (let i = 0; i < maxIterations; i++) {
          result += Math.sqrt(i) * Math.sin(i) + Math.cos(i);
          operations += 3;
        }
        break;

      case 'sqrt':
        for (let i = 0; i < maxIterations; i++) {
          result += Math.sqrt(i);
          operations++;
        }
        break;

      case 'trig':
        for (let i = 0; i < maxIterations; i++) {
          result += Math.sin(i) + Math.cos(i) + Math.tan(i);
          operations += 3;
        }
        break;

      case 'prime':
        let primes = 0;
        for (let num = 2; num < maxIterations && num < 100000; num++) {
          let isPrime = true;
          for (let i = 2; i <= Math.sqrt(num); i++) {
            if (num % i === 0) {
              isPrime = false;
              break;
            }
            operations++;
          }
          if (isPrime) primes++;
        }
        result = primes;
        break;

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }

    const duration = Date.now() - startTime;
    const opsPerSecond = operations / (duration / 1000);

    res.status(200).json({
      result,
      iterations: maxIterations,
      operation,
      operations,
      performance: {
        duration,
        opsPerSecond: Math.round(opsPerSecond),
        avgTimePerOp: (duration / operations).toFixed(6)
      },
      meta: {
        provider: 'gcp-functions',
        region: process.env.FUNCTION_REGION || 'unknown',
        memoryUsed: process.memoryUsage().heapUsed,
        cpuModel: process.arch,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

// Export for local testing
module.exports = {
  computeHash: functions.getFunction('computeHash'),
  analyzeText: functions.getFunction('analyzeText'),
  transformData: functions.getFunction('transformData'),
  heavyCompute: functions.getFunction('heavyCompute')
};
