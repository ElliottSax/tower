# DeepSeek AI Integration

Use DeepSeek's powerful AI models for code generation, reasoning, and technical tasks.

## Features

- ✅ **DeepSeek-Coder** - State-of-the-art code generation
- ✅ **DeepSeek-Chat** - Advanced reasoning and Q&A
- ✅ **Competitive pricing** - ~$0.14 per 1M tokens
- ✅ **High quality** - Rivals GPT-4 on many tasks
- ✅ **API compatible** - OpenAI-like API format
- ✅ **No deployment needed** - Use directly via API

## Quick Start

### 1. Get API Key

1. Sign up at https://platform.deepseek.com/
2. Go to API Keys section
3. Create a new API key
4. Save the key securely

### 2. Configure Orchestrator

```javascript
const Orchestrator = require('./multi-cloud-orchestrator/src/orchestrator');

const orchestrator = new Orchestrator({
  deepseek: {
    enabled: true,
    priority: 9,
    apiKey: 'sk-YOUR_DEEPSEEK_API_KEY',
    models: {
      'code-generation': 'deepseek-coder',
      'reasoning': 'deepseek-chat'
    }
  }
});
```

### 3. Use It

```javascript
// Code generation
const code = await orchestrator.submit({
  type: 'code-generation',
  payload: {
    prompt: 'Write a function to calculate fibonacci numbers'
  },
  provider: 'deepseek'
});

// Code review
const review = await orchestrator.submit({
  type: 'code-review',
  payload: {
    code: `
      function fibonacci(n) {
        if (n <= 1) return n;
        return fibonacci(n-1) + fibonacci(n-2);
      }
    `
  },
  provider: 'deepseek'
});

// Reasoning task
const answer = await orchestrator.submit({
  type: 'reasoning',
  payload: {
    question: 'Explain the difference between promises and async/await in JavaScript'
  },
  provider: 'deepseek'
});
```

## Supported Tasks

### Code Tasks

**Code Generation**
```javascript
{
  type: 'code-generation',
  payload: {
    prompt: 'Create a REST API endpoint for user authentication',
    language: 'javascript',  // optional
    maxTokens: 1000
  }
}
```

**Code Completion**
```javascript
{
  type: 'code-completion',
  payload: {
    code: 'function calculateSum(arr) {',
    maxTokens: 200
  }
}
```

**Code Explanation**
```javascript
{
  type: 'code-explanation',
  payload: {
    code: 'const result = await Promise.all(tasks.map(async t => t()))'
  }
}
```

**Code Review**
```javascript
{
  type: 'code-review',
  payload: {
    code: '// your code here'
  }
}
```

**Bug Fix**
```javascript
{
  type: 'bug-fix',
  payload: {
    code: 'function divide(a, b) { return a / b; }'
  }
}
```

**Refactoring**
```javascript
{
  type: 'refactoring',
  payload: {
    code: '// messy code to refactor'
  }
}
```

### AI Tasks

**Reasoning**
```javascript
{
  type: 'reasoning',
  payload: {
    question: 'What is the time complexity of quicksort?'
  }
}
```

**Chat**
```javascript
{
  type: 'chat',
  payload: {
    messages: [
      { role: 'user', content: 'Hello!' },
      { role: 'assistant', content: 'Hi! How can I help?' },
      { role: 'user', content: 'Explain REST APIs' }
    ]
  }
}
```

**Summarization**
```javascript
{
  type: 'summarization',
  payload: {
    text: 'Long technical document...'
  }
}
```

## Models

### DeepSeek-Coder
- **Best for:** Code generation, completion, explanation
- **Context:** 16K tokens
- **Cost:** ~$0.14 per 1M tokens
- **Quality:** Rivals CodeLlama and StarCoder

### DeepSeek-Chat
- **Best for:** Reasoning, Q&A, general chat
- **Context:** 64K tokens
- **Cost:** ~$0.14 per 1M tokens
- **Quality:** Competitive with GPT-3.5 Turbo

## Cost Comparison

| Task | Avg Tokens | Cost per Task |
|------|------------|---------------|
| Code generation | 500 | $0.00007 |
| Code completion | 200 | $0.000028 |
| Code explanation | 300 | $0.000042 |
| Code review | 400 | $0.000056 |
| Reasoning | 300 | $0.000042 |
| Chat message | 200 | $0.000028 |

**Example:** 1000 code generations = **$0.07** (7 cents)

Compare to OpenAI GPT-4:
- GPT-4: ~$0.03 per 1K tokens input, $0.06 per 1K tokens output
- DeepSeek: ~$0.00014 per 1K tokens (both input/output)

**DeepSeek is ~200x cheaper than GPT-4!**

## Direct API Usage

```javascript
async function generateCode(prompt) {
  const response = await fetch(
    'https://api.deepseek.com/v1/chat/completions',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'deepseek-coder',
        messages: [
          {
            role: 'system',
            content: 'You are an expert programmer.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 1000,
        temperature: 0.7
      })
    }
  );

  const result = await response.json();
  return result.choices[0].message.content;
}
```

## Example Use Cases

### 1. Code Generation Assistant

```javascript
async function generateFunction(description) {
  const result = await orchestrator.submit({
    type: 'code-generation',
    payload: {
      prompt: `Write a ${description} function in JavaScript with:
        - Input validation
        - Error handling
        - JSDoc comments
        - Unit test examples`,
      maxTokens: 1500
    },
    provider: 'deepseek'
  });

  const generated = await orchestrator.waitFor(result.id);
  return generated.text;
}

const code = await generateFunction('binary search');
```

### 2. Code Review Automation

```javascript
async function reviewPullRequest(files) {
  const reviews = await Promise.all(
    files.map(async file => {
      const result = await orchestrator.submit({
        type: 'code-review',
        payload: { code: file.content },
        provider: 'deepseek'
      });

      return {
        file: file.path,
        review: await orchestrator.waitFor(result.id)
      };
    })
  );

  return reviews;
}
```

### 3. Technical Q&A

```javascript
async function askTechnicalQuestion(question) {
  const result = await orchestrator.submit({
    type: 'reasoning',
    payload: {
      question,
      maxTokens: 1000
    },
    provider: 'deepseek'
  });

  const answer = await orchestrator.waitFor(result.id);
  return answer.text;
}

const explanation = await askTechnicalQuestion(
  'Explain the CAP theorem with practical examples'
);
```

### 4. Bug Detection

```javascript
async function findBugs(code) {
  const result = await orchestrator.submit({
    type: 'bug-fix',
    payload: {
      code,
      maxTokens: 1000
    },
    provider: 'deepseek'
  });

  const analysis = await orchestrator.waitFor(result.id);
  return analysis.text;
}
```

## Best Practices

1. **Use DeepSeek-Coder for code tasks** - It's specifically trained for programming
2. **Use DeepSeek-Chat for reasoning** - Better for general questions and chat
3. **Set appropriate max_tokens** - Prevents runaway costs
4. **Use temperature wisely**:
   - 0.0-0.3 for code generation (deterministic)
   - 0.7-0.9 for creative tasks
5. **Cache common queries** - Save on API costs

## Rate Limits

- **Free tier:** Limited requests (check current limits)
- **Paid tier:** Higher rate limits based on plan
- **Handle rate limits:** Implement exponential backoff

## Error Handling

```javascript
async function safeCodeGeneration(prompt, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const result = await orchestrator.submit({
        type: 'code-generation',
        payload: { prompt },
        provider: 'deepseek'
      });

      return await orchestrator.waitFor(result.id);
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(r => setTimeout(r, 1000 * Math.pow(2, i)));
    }
  }
}
```

## Comparison to Alternatives

| Provider | Code Quality | Cost (per 1M tokens) | Speed |
|----------|--------------|----------------------|-------|
| **DeepSeek** | ★★★★☆ | $0.14 | Fast |
| GPT-4 | ★★★★★ | $30-60 | Medium |
| Claude 3 | ★★★★★ | $15-75 | Medium |
| GPT-3.5 | ★★★☆☆ | $1.50 | Fast |
| CodeLlama | ★★★★☆ | Free (self-hosted) | Varies |

**DeepSeek offers the best cost/performance ratio for code tasks.**

## Limitations

- **Not as capable as GPT-4** - For cutting-edge tasks
- **English-focused** - Limited multilingual support
- **Code-centric** - Less good at creative writing
- **Newer service** - Smaller community than OpenAI

## Resources

- API Docs: https://platform.deepseek.com/api-docs/
- Models: https://platform.deepseek.com/models
- Pricing: https://platform.deepseek.com/pricing
- Community: https://discord.gg/deepseek (if available)

## Why Use DeepSeek?

✅ **Cost-effective** - 200x cheaper than GPT-4
✅ **High quality** - Competitive with commercial models
✅ **Code-specialized** - Excellent for programming tasks
✅ **Fast** - Quick response times
✅ **OpenAI compatible** - Easy migration from OpenAI API

**Perfect for:** Code generation, technical documentation, code review automation, developer tools
