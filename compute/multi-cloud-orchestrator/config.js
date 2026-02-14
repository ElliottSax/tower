/**
 * Multi-Cloud Orchestrator Configuration
 * All 6+ platforms configured and ready!
 *
 * API keys are loaded from environment variables.
 * Copy .env.example to .env and fill in your keys.
 * Install dotenv: npm install dotenv
 */
require('dotenv').config();

module.exports = {
  // 1. Cloudflare Workers (Edge compute)
  cloudflare: {
    enabled: true,
    priority: 10,
    apiUrl: process.env.CLOUDFLARE_API_URL || '',
    apiKey: process.env.CLOUDFLARE_API_KEY || ''
  },

  // 2. AWS Lambda (Heavy compute) - needs AWS credentials
  aws: {
    enabled: false, // Enable after AWS configure
    priority: 8,
    region: process.env.AWS_REGION || 'us-east-1',
    endpoints: {
      // Add after deployment
    }
  },

  // 3. Google Cloud Functions (Data processing)
  gcp: {
    enabled: true,
    priority: 7,
    projectId: process.env.GCP_PROJECT_ID || '',
    region: process.env.GCP_REGION || 'us-central1',
    endpoints: {
      // Will be updated after deployment
    }
  },

  // 4. Hugging Face (ML inference via Inference Providers API)
  // Uses OpenAI-compatible router endpoint: router.huggingface.co/v1/chat/completions
  huggingface: {
    enabled: true,
    priority: 9,
    apiKey: process.env.HUGGINGFACE_API_KEY || '',
    models: {
      'text-generation': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'sentiment-analysis': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'summarization': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'question-answering': 'Qwen/Qwen2.5-7B-Instruct-1M',
      'code-generation': 'Qwen/Qwen2.5-Coder-32B-Instruct',
      'text-to-image': 'stabilityai/stable-diffusion-2',
      'embeddings': 'sentence-transformers/all-MiniLM-L6-v2'
    }
  },

  // 5. DeepSeek (AI code generation)
  deepseek: {
    enabled: true,
    priority: 9,
    apiKey: process.env.DEEPSEEK_API_KEY || '',
    models: {
      'code-generation': 'deepseek-coder',
      'reasoning': 'deepseek-chat'
    }
  },

  // 6. Replit (Quick deployment) - needs manual web deployment
  replit: {
    enabled: false, // Enable after deploying to replit.com
    priority: 6,
    endpoints: {
      // Add after deployment
    }
  },

  // BONUS: Additional AI Providers (from your API keys)

  // Grok/XAI
  grok: {
    enabled: true,
    priority: 8,
    apiKey: process.env.GROK_API_KEY || ''
  },

  // OpenRouter (access to 100+ models)
  openrouter: {
    enabled: true,
    priority: 8,
    apiKey: process.env.OPENROUTER_API_KEY || ''
  },

  // Together AI
  together: {
    enabled: true,
    priority: 7,
    apiKey: process.env.TOGETHER_API_KEY || ''
  },

  // Groq (fastest inference)
  groq: {
    enabled: true,
    priority: 9,
    apiKey: process.env.GROQ_API_KEY || ''
  },

  // Replicate
  replicate: {
    enabled: true,
    priority: 7,
    apiKey: process.env.REPLICATE_API_KEY || ''
  },

  // Cerebras (ultra-fast inference)
  cerebras: {
    enabled: true,
    priority: 8,
    apiKey: process.env.CEREBRAS_API_KEY || ''
  },

  // Fireworks AI
  fireworks: {
    enabled: true,
    priority: 7,
    apiKey: process.env.FIREWORKS_API_KEY || ''
  },

  // Local fallback
  local: {
    enabled: true,
    priority: 1
  }
};
