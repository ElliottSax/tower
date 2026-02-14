/**
 * AWS Lambda: Hash Computation
 *
 * Generates SHA-256 hash of input text
 */

const crypto = require('crypto');

exports.handler = async (event) => {
  const startTime = Date.now();

  try {
    // Parse input
    const body = JSON.parse(event.body || '{}');
    const text = body.text || '';

    // Generate hash
    const hash = crypto.createHash('sha256').update(text).digest('hex');

    // Calculate processing time
    const duration = Date.now() - startTime;

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
      },
      body: JSON.stringify({
        hash,
        length: text.length,
        algorithm: 'sha256',
        duration,
        provider: 'aws-lambda',
        region: process.env.AWS_REGION,
        timestamp: new Date().toISOString()
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
