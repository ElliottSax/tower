# Hugging Face Inference API Integration

Use Hugging Face's serverless Inference API for ML tasks without deploying your own infrastructure.

## Features

- ✅ **100,000+ pre-trained models** - Access state-of-the-art ML models
- ✅ **No deployment needed** - Use models directly via API
- ✅ **Multiple tasks** - Text, image, audio, video processing
- ✅ **Free tier** - 30,000 characters/month free
- ✅ **Serverless** - No infrastructure to manage
- ✅ **Global CDN** - Fast inference worldwide

## Quick Start

### 1. Get API Key

1. Sign up at https://huggingface.co/
2. Go to https://huggingface.co/settings/tokens
3. Create a new token with "Inference API" permission
4. Save the token

### 2. Configure Orchestrator

```javascript
const Orchestrator = require('./multi-cloud-orchestrator/src/orchestrator');

const orchestrator = new Orchestrator({
  huggingface: {
    enabled: true,
    priority: 9,
    apiKey: 'hf_YOUR_API_KEY_HERE',
    models: {
      'text-generation': 'gpt2',
      'sentiment-analysis': 'distilbert-base-uncased-finetuned-sst-2-english',
      'summarization': 'facebook/bart-large-cnn',
      'text-to-image': 'stabilityai/stable-diffusion-2'
    }
  }
});
```

### 3. Use It

```javascript
// Text generation
const result = await orchestrator.submit({
  type: 'text-generation',
  payload: {
    text: 'Once upon a time',
    maxLength: 100
  },
  provider: 'huggingface'
});

// Sentiment analysis
const sentiment = await orchestrator.submit({
  type: 'sentiment-analysis',
  payload: {
    text: 'I love this product!'
  },
  provider: 'huggingface'
});

// Text summarization
const summary = await orchestrator.submit({
  type: 'summarization',
  payload: {
    text: 'Very long article text here...'
  },
  provider: 'huggingface'
});

// Text-to-image
const image = await orchestrator.submit({
  type: 'text-to-image',
  payload: {
    prompt: 'A beautiful sunset over mountains',
    width: 512,
    height: 512
  },
  provider: 'huggingface'
});
```

## Supported Tasks

### Text Tasks

**Text Generation**
```javascript
{
  type: 'text-generation',
  payload: {
    text: 'The quick brown',
    maxLength: 50,
    temperature: 0.7
  }
}
```

**Sentiment Analysis**
```javascript
{
  type: 'sentiment-analysis',
  payload: {
    text: 'I love this product!'
  }
}
// Result: { label: 'POSITIVE', score: 0.9998 }
```

**Summarization**
```javascript
{
  type: 'summarization',
  payload: {
    text: 'Long article text...',
    maxLength: 130,
    minLength: 30
  }
}
```

**Translation**
```javascript
{
  type: 'translation',
  payload: {
    text: 'Hello, how are you?',
    model: 't5-base'  // or specific translation model
  }
}
```

**Question Answering**
```javascript
{
  type: 'question-answering',
  payload: {
    question: 'What is the capital of France?',
    context: 'France is a country in Europe. Paris is its capital.'
  }
}
```

**Zero-Shot Classification**
```javascript
{
  type: 'zero-shot-classification',
  payload: {
    text: 'This is a great movie!',
    labels: ['positive', 'negative', 'neutral']
  }
}
```

### Image Tasks

**Text-to-Image**
```javascript
{
  type: 'text-to-image',
  payload: {
    prompt: 'A futuristic city at sunset',
    width: 512,
    height: 512,
    steps: 50
  }
}
// Result: { image: 'base64...' }
```

**Image Classification**
```javascript
{
  type: 'image-classification',
  payload: {
    image: 'base64_image_data' // or URL
  }
}
```

### Embeddings

**Feature Extraction**
```javascript
{
  type: 'embeddings',
  payload: {
    text: 'Convert this text to embeddings'
  }
}
// Result: array of vectors
```

## Popular Models

### Text Generation
- `gpt2` - GPT-2 text generation
- `EleutherAI/gpt-neo-2.7B` - Larger GPT-Neo model
- `facebook/opt-1.3b` - OPT model

### Text Classification
- `distilbert-base-uncased-finetuned-sst-2-english` - Sentiment
- `facebook/bart-large-mnli` - Zero-shot classification

### Summarization
- `facebook/bart-large-cnn` - News summarization
- `google/pegasus-xsum` - Extreme summarization

### Translation
- `Helsinki-NLP/opus-mt-en-es` - English to Spanish
- `t5-base` - Multi-task model

### Text-to-Image
- `stabilityai/stable-diffusion-2` - Stable Diffusion
- `runwayml/stable-diffusion-v1-5` - SD v1.5
- `CompVis/stable-diffusion-v1-4` - SD v1.4

### Image Classification
- `google/vit-base-patch16-224` - Vision Transformer
- `microsoft/resnet-50` - ResNet-50

### Embeddings
- `sentence-transformers/all-MiniLM-L6-v2` - Fast embeddings
- `sentence-transformers/all-mpnet-base-v2` - Better quality

## Cost

### Free Tier
- 30,000 characters/month
- Rate limited to ~100 requests/hour
- Perfect for development and testing

### Pro Tier ($9/month)
- 10M characters/month
- Higher rate limits
- Priority access to models

### Enterprise
- Custom pricing
- Dedicated endpoints
- SLA guarantees

## Direct API Usage

You can also use Hugging Face directly without the orchestrator:

```javascript
async function generateText(prompt) {
  const response = await fetch(
    'https://api-inference.huggingface.co/models/gpt2',
    {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer hf_YOUR_KEY',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        inputs: prompt,
        parameters: { max_length: 100 }
      })
    }
  );

  return response.json();
}
```

## Examples

### Complete Text Generation Example

```javascript
const Orchestrator = require('./multi-cloud-orchestrator/src/orchestrator');

const orchestrator = new Orchestrator({
  huggingface: {
    enabled: true,
    apiKey: process.env.HUGGINGFACE_API_KEY
  }
});

async function generateStory() {
  const result = await orchestrator.submit({
    type: 'text-generation',
    payload: {
      text: 'In a world where AI and humans coexist',
      maxLength: 200,
      temperature: 0.8,
      numSequences: 3
    },
    provider: 'huggingface'
  });

  const generated = await orchestrator.waitFor(result.id);
  console.log(generated.result);
}
```

### Sentiment Analysis Pipeline

```javascript
async function analyzeSentiments(reviews) {
  const jobs = reviews.map(review =>
    orchestrator.submit({
      type: 'sentiment-analysis',
      payload: { text: review },
      provider: 'huggingface'
    })
  );

  const results = await Promise.all(
    jobs.map(job => orchestrator.waitFor(job.id))
  );

  return results.map(r => r.result[0]);
}

const reviews = [
  'This product is amazing!',
  'Terrible quality, waste of money',
  'Pretty good, would recommend'
];

const sentiments = await analyzeSentiments(reviews);
```

### Image Generation

```javascript
async function generateImage(prompt) {
  const result = await orchestrator.submit({
    type: 'text-to-image',
    payload: {
      prompt,
      width: 768,
      height: 768,
      steps: 50
    },
    provider: 'huggingface'
  });

  const generated = await orchestrator.waitFor(result.id);

  // Save base64 image
  const fs = require('fs');
  fs.writeFileSync('output.png', Buffer.from(generated.image, 'base64'));
}

await generateImage('A serene mountain landscape at dawn');
```

## Rate Limits

Free tier limits:
- ~100 requests per hour
- May experience cold starts (30s-2min for first request)
- Shared infrastructure

Pro tier:
- Higher rate limits
- Faster warm-up times
- Priority queuing

## Best Practices

1. **Cache results** - ML inference is expensive, cache when possible
2. **Batch requests** - Process multiple items together
3. **Use appropriate models** - Smaller models are faster and cheaper
4. **Handle rate limits** - Implement exponential backoff
5. **Optimize prompts** - Better prompts = better results

## Troubleshooting

### Model Loading Error
If you see "Model is loading", wait 30-60 seconds and retry. Models cold-start on first use.

### Rate Limit Exceeded
Wait before retrying or upgrade to Pro tier.

### API Key Invalid
Check that your token has "Inference API" permission at https://huggingface.co/settings/tokens

## Resources

- API Docs: https://huggingface.co/docs/api-inference/
- Models: https://huggingface.co/models
- Pricing: https://huggingface.co/pricing
