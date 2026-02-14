/**
 * AWS Lambda: Heavy Computation
 *
 * CPU-intensive calculations for benchmarking
 */

exports.handler = async (event) => {
  const startTime = Date.now();

  try {
    const body = JSON.parse(event.body || '{}');
    const iterations = Math.min(Number(body.iterations) || 100000, 10000000);
    const operation = body.operation || 'mixed';

    let result = 0;
    let operations = 0;

    switch (operation) {
      case 'mixed':
        // Mixed math operations
        for (let i = 0; i < iterations; i++) {
          result += Math.sqrt(i) * Math.sin(i) + Math.cos(i);
          operations += 3;
        }
        break;

      case 'sqrt':
        // Square root only
        for (let i = 0; i < iterations; i++) {
          result += Math.sqrt(i);
          operations++;
        }
        break;

      case 'trig':
        // Trigonometric operations
        for (let i = 0; i < iterations; i++) {
          result += Math.sin(i) + Math.cos(i) + Math.tan(i);
          operations += 3;
        }
        break;

      case 'prime':
        // Prime number calculation
        let primes = 0;
        for (let num = 2; num < iterations && num < 100000; num++) {
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

      case 'fibonacci':
        // Fibonacci sequence
        let a = 0, b = 1;
        const sequence = [a, b];
        for (let i = 2; i < Math.min(iterations, 10000); i++) {
          const next = a + b;
          sequence.push(next);
          a = b;
          b = next;
          operations++;
        }
        result = b;
        break;

      default:
        throw new Error(`Unknown operation: ${operation}`);
    }

    const duration = Date.now() - startTime;
    const opsPerSecond = operations / (duration / 1000);

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
      },
      body: JSON.stringify({
        result,
        iterations,
        operation,
        operations,
        performance: {
          duration,
          opsPerSecond: Math.round(opsPerSecond),
          avgTimePerOp: (duration / operations).toFixed(6)
        },
        meta: {
          provider: 'aws-lambda',
          region: process.env.AWS_REGION,
          memoryLimit: process.env.AWS_LAMBDA_FUNCTION_MEMORY_SIZE,
          memoryUsed: process.memoryUsage().heapUsed,
          cpuModel: process.arch,
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
