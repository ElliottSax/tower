/**
 * AWS Lambda: Data Transformation
 *
 * Performs various operations on arrays of data
 */

exports.handler = async (event) => {
  const startTime = Date.now();

  try {
    const body = JSON.parse(event.body || '{}');
    const data = body.data || [];
    const operation = body.operation || 'sort';

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

      case 'filter':
        const condition = body.condition || 'positive';
        if (condition === 'positive') {
          result = data.filter(n => Number(n) > 0);
        } else if (condition === 'negative') {
          result = data.filter(n => Number(n) < 0);
        } else if (condition === 'even') {
          result = data.filter(n => Number(n) % 2 === 0);
        } else if (condition === 'odd') {
          result = data.filter(n => Number(n) % 2 !== 0);
        }
        stats.inputSize = data.length;
        stats.outputSize = result.length;
        stats.filtered = data.length - result.length;
        break;

      case 'map':
        const mapOperation = body.mapOperation || 'square';
        if (mapOperation === 'square') {
          result = data.map(n => Number(n) ** 2);
        } else if (mapOperation === 'sqrt') {
          result = data.map(n => Math.sqrt(Number(n)));
        } else if (mapOperation === 'abs') {
          result = data.map(n => Math.abs(Number(n)));
        }
        stats.inputSize = data.length;
        break;

      case 'reduce':
        const reduceOperation = body.reduceOperation || 'sum';
        if (reduceOperation === 'sum') {
          result = data.reduce((acc, n) => acc + Number(n), 0);
        } else if (reduceOperation === 'product') {
          result = data.reduce((acc, n) => acc * Number(n), 1);
        } else if (reduceOperation === 'min') {
          result = data.reduce((min, n) => Math.min(min, Number(n)), Infinity);
        } else if (reduceOperation === 'max') {
          result = data.reduce((max, n) => Math.max(max, Number(n)), -Infinity);
        }
        stats.inputSize = data.length;
        break;

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }

    const duration = Date.now() - startTime;

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
      },
      body: JSON.stringify({
        result,
        operation,
        stats,
        meta: {
          duration,
          provider: 'aws-lambda',
          region: process.env.AWS_REGION,
          memoryUsed: process.memoryUsage().heapUsed,
          timestamp: new Date().toISOString()
        }
      })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Internal Server Error',
        message: error.message
      })
    };
  }
};
