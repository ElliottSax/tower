/**
 * Replit Deployment - Compute Worker
 *
 * A simple Express server that handles compute tasks
 * Deploy this to Replit and it becomes a serverless endpoint
 */

const express = require('express');
const crypto = require('crypto');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Health check
app.get('/', (req, res) => {
  res.json({
    status: 'healthy',
    provider: 'replit',
    timestamp: new Date().toISOString()
  });
});

// Hash computation
app.post('/compute/hash', (req, res) => {
  const startTime = Date.now();

  try {
    const { text = '' } = req.body;
    const hash = crypto.createHash('sha256').update(text).digest('hex');

    res.json({
      hash,
      length: text.length,
      algorithm: 'sha256',
      duration: Date.now() - startTime,
      provider: 'replit',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

// Text analysis
app.post('/compute/text-analysis', (req, res) => {
  const startTime = Date.now();

  try {
    const { text = '' } = req.body;

    const words = text.split(/\s+/).filter(w => w.length > 0);
    const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
    const paragraphs = text.split(/\n\n+/).filter(p => p.trim().length > 0);

    const wordLengths = words.map(w => w.length);
    const avgWordLength = wordLengths.reduce((a, b) => a + b, 0) / (words.length || 1);

    const letters = text.match(/[a-zA-Z]/g) || [];
    const uppercase = text.match(/[A-Z]/g) || [];
    const uniqueWords = new Set(words.map(w => w.toLowerCase()));

    res.json({
      text: {
        length: text.length,
        words: words.length,
        sentences: sentences.length,
        paragraphs: paragraphs.length,
        uniqueWords: uniqueWords.size
      },
      words: {
        count: words.length,
        avgLength: parseFloat(avgWordLength.toFixed(2)),
        unique: uniqueWords.size,
        uniqueRatio: parseFloat((uniqueWords.size / (words.length || 1)).toFixed(3))
      },
      characters: {
        total: text.length,
        letters: letters.length,
        uppercase: uppercase.length,
        uppercaseRatio: parseFloat((uppercase.length / (letters.length || 1)).toFixed(3))
      },
      meta: {
        duration: Date.now() - startTime,
        provider: 'replit',
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

// Data transformation
app.post('/compute/data-transform', (req, res) => {
  const startTime = Date.now();

  try {
    const { data = [], operation = 'sort' } = req.body;

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
        break;

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }

    res.json({
      result,
      operation,
      stats,
      meta: {
        duration: Date.now() - startTime,
        provider: 'replit',
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

// Heavy compute
app.post('/compute/heavy', (req, res) => {
  const startTime = Date.now();

  try {
    const { iterations = 100000, operation = 'mixed' } = req.body;
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

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }

    const duration = Date.now() - startTime;

    res.json({
      result,
      iterations: maxIterations,
      operation,
      operations,
      performance: {
        duration,
        opsPerSecond: Math.round(operations / (duration / 1000))
      },
      meta: {
        provider: 'replit',
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

app.listen(PORT, () => {
  console.log(`Replit Compute Worker running on port ${PORT}`);
  console.log(`Deploy this to Replit for serverless compute!`);
});
