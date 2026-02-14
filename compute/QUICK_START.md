# 🚀 QUICK START - Multi-Cloud AI Platform

Get started with your operational multi-cloud AI system in 60 seconds.

## ⚡ Fastest Way to Use (Right Now!)

### Option 1: Direct API Calls (No setup)

**Groq (Ultra-fast, FREE):**
```bash
curl -X POST "https://api.groq.com/openai/v1/chat/completions" \
  -H "Authorization: Bearer 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" \
  -H "Content-Type: application/json" \
  -d '{"model":"llama-3.3-70b-versatile","messages":[{"role":"user","content":"Your question here"}]}'
```

**DeepSeek (Code generation):**
```bash
curl -X POST "https://api.deepseek.com/v1/chat/completions" \
  -H "Authorization: Bearer sk-d00907cc293f4655b8502be6d389df03" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"Write a Python function"}]}'
```

**Cerebras (Fast):**
```bash
curl -X POST "https://api.cerebras.ai/v1/chat/completions" \
  -H "Authorization: Bearer csk-8n6j6kynyjtm55j24mwdw6x2y9c24859fkddywyek3kdd85y" \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.1-8b","messages":[{"role":"user","content":"Hi"}]}'
```

---

### Option 2: Orchestrator (Smart Routing)

```bash
cd /mnt/e/projects/compute/multi-cloud-orchestrator
node test-orchestrator.js
```

**Or use in your code:**
```javascript
const Orchestrator = require('./src/orchestrator');
const config = require('./config');

const orchestrator = new Orchestrator(config);

// Automatic routing to best provider
const job = await orchestrator.submit({
  type: 'chat',
  payload: { 
    messages: [{ role: 'user', content: 'What is 2+2?' }]
  },
  requirements: { latency: 'low' }
});

const result = await orchestrator.waitFor(job.id);
console.log(result.text); // Routes to Groq (fastest)
```

---

## 📊 What's Working Right Now

| Platform | Status | Speed | Use For |
|----------|--------|-------|---------|
| **Groq** | ✅ 100% | ⚡ 1,412 tok/s | Chat, real-time |
| **DeepSeek** | ✅ Working | Fast | Code generation |
| **Cerebras** | ✅ Working | Very fast | General AI |
| **Replicate** | ✅ Working | Medium | Image/video ML |

---

## 🧪 Test Everything

```bash
cd /mnt/e/projects/compute/multi-cloud-orchestrator

# Test only working platforms
node test-working-platforms.js

# Test orchestrator with smart routing
node test-orchestrator.js

# Test all platforms (some may fail)
node test-all-platforms.js
```

---

## 📈 Cost Estimate

**10,000 operations per month:**
- Groq: $0.00 (free tier)
- DeepSeek: ~$0.07
- Cerebras: ~$0.05
- **Total: ~$0.12/month**

---

## 🎯 Recommended Usage

**For Chat/Conversation:**
→ Use Groq (free, ultra-fast, 100% success)

**For Code Generation:**
→ Use DeepSeek (specialized for code)

**For General AI Tasks:**
→ Use Cerebras (fast, reliable)

**For Image/Video ML:**
→ Use Replicate (specialized models)

---

## 🔧 Common Tasks

**Test a specific provider:**
```javascript
const GroqProvider = require('./src/providers/groq');
const provider = new GroqProvider({ apiKey: 'your-key' });

const result = await provider.execute({
  type: 'chat',
  payload: { 
    messages: [{ role: 'user', content: 'Hi' }] 
  }
});
```

**Batch processing:**
```javascript
const tasks = [
  { type: 'chat', payload: { messages: [...] } },
  { type: 'code-generation', payload: { prompt: '...' } },
  // ... more tasks
];

const jobs = await orchestrator.submitBatch(tasks);
```

**Cost tracking:**
```javascript
const costs = await orchestrator.getCosts();
console.log(`Total: $${costs.total}`);
console.log(costs.breakdown); // Per-provider breakdown
```

---

## 📚 Full Documentation

- `DEPLOYMENT_STATUS.md` - Complete status & metrics
- `WORKING_PLATFORMS.md` - Platform details
- `LIVE_PLATFORMS.md` - All platform info

---

## 💡 Pro Tips

1. **Use Groq for development** - Free, fast, reliable
2. **Use DeepSeek for code** - Best at programming tasks
3. **Orchestrator handles routing** - Automatically picks best provider
4. **Monitor costs** - Built-in cost tracking per platform
5. **Batch requests** - Process multiple tasks efficiently

---

**Your multi-cloud AI system is ready to use! Start with Groq for instant results.** 🚀
