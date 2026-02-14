/**
 * AWS Lambda: Image Processing
 *
 * Resize, optimize, and transform images using Sharp
 * Requires: sharp npm package
 */

const sharp = require('sharp');
const https = require('https');
const http = require('http');

// Download image from URL
function downloadImage(url) {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;

    protocol.get(url, (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`Failed to download image: ${response.statusCode}`));
        return;
      }

      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => resolve(Buffer.concat(chunks)));
      response.on('error', reject);
    }).on('error', reject);
  });
}

exports.handler = async (event) => {
  const startTime = Date.now();

  try {
    const body = JSON.parse(event.body || '{}');

    // Input can be URL or base64
    const imageUrl = body.url;
    const imageBase64 = body.base64;
    const operation = body.operation || 'resize';

    let inputBuffer;

    if (imageUrl) {
      inputBuffer = await downloadImage(imageUrl);
    } else if (imageBase64) {
      inputBuffer = Buffer.from(imageBase64, 'base64');
    } else {
      throw new Error('Either url or base64 image required');
    }

    const metadata = await sharp(inputBuffer).metadata();
    let outputBuffer;
    let outputMetadata = {};

    switch (operation) {
      case 'resize':
        const width = body.width || 800;
        const height = body.height || null;
        outputBuffer = await sharp(inputBuffer)
          .resize(width, height, { fit: 'inside', withoutEnlargement: true })
          .toBuffer();
        outputMetadata = await sharp(outputBuffer).metadata();
        break;

      case 'thumbnail':
        const thumbSize = body.size || 200;
        outputBuffer = await sharp(inputBuffer)
          .resize(thumbSize, thumbSize, { fit: 'cover' })
          .toBuffer();
        outputMetadata = await sharp(outputBuffer).metadata();
        break;

      case 'format':
        const format = body.format || 'jpeg';
        const quality = body.quality || 80;
        outputBuffer = await sharp(inputBuffer)
          .toFormat(format, { quality })
          .toBuffer();
        outputMetadata = await sharp(outputBuffer).metadata();
        break;

      case 'optimize':
        outputBuffer = await sharp(inputBuffer)
          .jpeg({ quality: 85, progressive: true })
          .toBuffer();
        outputMetadata = await sharp(outputBuffer).metadata();
        break;

      case 'grayscale':
        outputBuffer = await sharp(inputBuffer)
          .grayscale()
          .toBuffer();
        outputMetadata = await sharp(outputBuffer).metadata();
        break;

      case 'blur':
        const sigma = body.sigma || 5;
        outputBuffer = await sharp(inputBuffer)
          .blur(sigma)
          .toBuffer();
        outputMetadata = await sharp(outputBuffer).metadata();
        break;

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }

    const duration = Date.now() - startTime;
    const compressionRatio = ((1 - (outputBuffer.length / inputBuffer.length)) * 100).toFixed(2);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
      },
      body: JSON.stringify({
        success: true,
        operation,
        input: {
          format: metadata.format,
          width: metadata.width,
          height: metadata.height,
          size: inputBuffer.length,
          hasAlpha: metadata.hasAlpha
        },
        output: {
          format: outputMetadata.format,
          width: outputMetadata.width,
          height: outputMetadata.height,
          size: outputBuffer.length,
          base64: outputBuffer.toString('base64')
        },
        stats: {
          compressionRatio: `${compressionRatio}%`,
          sizeReduction: inputBuffer.length - outputBuffer.length
        },
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
