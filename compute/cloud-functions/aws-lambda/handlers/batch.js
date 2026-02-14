/**
 * AWS Lambda: Batch Orchestrator
 *
 * Orchestrates batch processing by invoking other Lambda functions
 */

const { LambdaClient, InvokeCommand } = require('@aws-sdk/client-lambda');

const lambda = new LambdaClient({ region: process.env.AWS_REGION });

exports.handler = async (event) => {
  const startTime = Date.now();

  try {
    const body = JSON.parse(event.body || '{}');
    const tasks = body.tasks || [];
    const functionPrefix = body.functionPrefix || 'compute-workers-dev';

    if (!Array.isArray(tasks) || tasks.length === 0) {
      throw new Error('tasks array is required');
    }

    // Map task types to Lambda function names
    const functionMap = {
      'hash': `${functionPrefix}-computeHash`,
      'text-analysis': `${functionPrefix}-analyzeText`,
      'data-transform': `${functionPrefix}-transformData`,
      'heavy-compute': `${functionPrefix}-heavyCompute`,
      'image': `${functionPrefix}-processImage`
    };

    const results = [];
    const errors = [];

    // Process tasks in parallel
    const promises = tasks.map(async (task, index) => {
      try {
        const functionName = functionMap[task.type];

        if (!functionName) {
          throw new Error(`Unknown task type: ${task.type}`);
        }

        const command = new InvokeCommand({
          FunctionName: functionName,
          InvocationType: 'RequestResponse',
          Payload: JSON.stringify({
            body: JSON.stringify(task.payload || {})
          })
        });

        const response = await lambda.send(command);
        const payload = JSON.parse(Buffer.from(response.Payload).toString());
        const result = JSON.parse(payload.body);

        results[index] = {
          taskIndex: index,
          type: task.type,
          success: true,
          result
        };
      } catch (error) {
        errors.push({
          taskIndex: index,
          type: task.type,
          error: error.message
        });

        results[index] = {
          taskIndex: index,
          type: task.type,
          success: false,
          error: error.message
        };
      }
    });

    await Promise.all(promises);

    const duration = Date.now() - startTime;

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
      },
      body: JSON.stringify({
        success: true,
        totalTasks: tasks.length,
        successfulTasks: results.filter(r => r.success).length,
        failedTasks: errors.length,
        results,
        errors: errors.length > 0 ? errors : undefined,
        meta: {
          duration,
          avgDurationPerTask: (duration / tasks.length).toFixed(2),
          provider: 'aws-lambda',
          region: process.env.AWS_REGION,
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
