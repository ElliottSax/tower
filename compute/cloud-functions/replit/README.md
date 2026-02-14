# Replit Deployments - Compute Workers

Deploy serverless compute functions to Replit's platform with zero configuration.

## Features

- ✅ **Zero config deployment** - Deploy directly from Replit IDE
- ✅ **Instant HTTPS** - Get a URL immediately
- ✅ **Collaborative** - Edit with your team in real-time
- ✅ **Always-on** - Deployments stay awake
- ✅ **Flat pricing** - $7-20/month unlimited deployments
- ✅ **Built-in database** - Replit DB included

## Quick Start

### Option 1: Deploy via Replit Website

1. Go to https://replit.com/
2. Click "Create Repl"
3. Choose "Node.js"
4. Name it "compute-worker"
5. Copy the code from `compute-worker/index.js`
6. Paste into `index.js`
7. Copy `package.json` content
8. Click "Run"
9. Click "Deploy" → "Autoscale deployment"
10. Get your deployment URL (e.g., `https://compute-worker.username.repl.co`)

### Option 2: Deploy from Local Files

1. Copy the `compute-worker` folder to a Replit
2. Open Replit and import from GitHub or upload files
3. Click "Deploy"
4. Get your URL

### Option 3: Use Replit CLI

```bash
# Install Replit CLI
npm install -g @replit/cli

# Login
replit login

# Deploy
cd compute-worker
replit deploy
```

## Endpoints

Once deployed, your Replit worker will have these endpoints:

### Health Check
```bash
GET https://YOUR-REPL.username.repl.co/
```

### Hash Computation
```bash
POST https://YOUR-REPL.username.repl.co/compute/hash
Content-Type: application/json

{
  "text": "Hello Replit!"
}
```

### Text Analysis
```bash
POST https://YOUR-REPL.username.repl.co/compute/text-analysis
Content-Type: application/json

{
  "text": "Analyze this text on Replit's infrastructure."
}
```

### Data Transform
```bash
POST https://YOUR-REPL.username.repl.co/compute/data-transform
Content-Type: application/json

{
  "data": [5, 2, 8, 1, 9],
  "operation": "sort"
}
```

### Heavy Compute
```bash
POST https://YOUR-REPL.username.repl.co/compute/heavy
Content-Type: application/json

{
  "iterations": 100000,
  "operation": "mixed"
}
```

## Integration with Orchestrator

After deploying, add to your orchestrator config:

```javascript
const orchestrator = new Orchestrator({
  replit: {
    enabled: true,
    priority: 6,
    endpoints: {
      'hash': 'https://YOUR-REPL.username.repl.co/compute/hash',
      'text-analysis': 'https://YOUR-REPL.username.repl.co/compute/text-analysis',
      'data-transform': 'https://YOUR-REPL.username.repl.co/compute/data-transform',
      'heavy-compute': 'https://YOUR-REPL.username.repl.co/compute/heavy'
    }
  }
});
```

## Pricing

### Hacker Plan ($7/month)
- Unlimited deployments
- Always-on deployments
- Custom domains
- 0.5 vCPU, 512MB RAM per deployment

### Pro Plan ($20/month)
- Everything in Hacker
- More resources (2 vCPU, 2GB RAM)
- Priority support
- Higher rate limits

### Teams Plan ($40/user/month)
- Everything in Pro
- Team collaboration features
- Admin controls
- SSO

## Advantages

### For Development
- **Instant deployment** - No build/deploy pipeline needed
- **Live editing** - Edit code and see changes immediately
- **Collaborative** - Multiple devs can edit together
- **Integrated IDE** - Code, test, deploy all in browser

### For Production
- **Always-on** - Deployments don't sleep (unlike free Heroku)
- **Auto-scaling** - Scales based on traffic
- **Built-in monitoring** - View logs and metrics
- **Custom domains** - Use your own domain

## Limitations

- **Cold starts** - Initial requests may be slower
- **Resource limits** - Max 2 vCPU, 2GB RAM
- **No GPUs** - Not suitable for ML training
- **Network limits** - Some ports blocked

## Advanced Features

### Add Database

Replit includes a built-in key-value database:

```javascript
const Database = require('@replit/database');
const db = new Database();

// Store
await db.set('key', 'value');

// Retrieve
const value = await db.get('key');
```

### Add Secrets

Store API keys securely:

1. Go to "Secrets" tab in Replit
2. Add key-value pairs
3. Access via `process.env.SECRET_NAME`

### Add Cron Jobs

Schedule tasks:

```javascript
const cron = require('node-cron');

cron.schedule('0 * * * *', () => {
  console.log('Running task every hour');
});
```

## Example Usage

```javascript
// Use the deployed Replit worker
async function hashOnReplit(text) {
  const response = await fetch(
    'https://YOUR-REPL.username.repl.co/compute/hash',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text })
    }
  );

  return response.json();
}

const result = await hashOnReplit('Hello World');
console.log(result.hash);
```

## Monitoring

View logs in real-time:
1. Go to your Repl
2. Click "Deployments"
3. Click on your deployment
4. View "Logs" tab

## Troubleshooting

### Deployment Failed
- Check that all dependencies are in package.json
- Ensure your app listens on `process.env.PORT`
- Check logs for errors

### 502 Bad Gateway
- Your app might have crashed
- Check logs for startup errors
- Ensure main file is specified correctly

### Slow Response
- Cold start on first request
- Consider upgrading to Pro for more resources
- Optimize your code

## Resources

- Replit Docs: https://docs.replit.com/
- Deployments Guide: https://docs.replit.com/deployments/
- Pricing: https://replit.com/pricing
- Community: https://ask.replit.com/
