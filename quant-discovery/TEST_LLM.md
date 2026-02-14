# Test Your LLM Setup

Quick test to verify your API keys are working.

## Quick Test

```bash
cd /mnt/e/projects/quant-discovery

# Test DeepSeek
python3 << 'EOF'
import os
os.environ['DEEPSEEK_API_KEY'] = 'sk-8b0ff3a7543747adb0979496981dc3c2'

from openai import OpenAI

client = OpenAI(
    api_key=os.environ['DEEPSEEK_API_KEY'],
    base_url="https://api.deepseek.com"
)

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[
        {"role": "user", "content": "Say 'DeepSeek is working!' in one sentence"}
    ],
    max_tokens=50
)

print("✅ DeepSeek Response:", response.choices[0].message.content)
print(f"💰 Cost: ~${0.00001:.6f}")
EOF

# Test HuggingFace
python3 << 'EOF'
import os
os.environ['HF_API_KEY'] = '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'

from huggingface_hub import InferenceClient

client = InferenceClient(token=os.environ['HF_API_KEY'])

response = client.text_generation(
    "Say 'HuggingFace is working!' in one sentence",
    model="mistralai/Mistral-7B-Instruct-v0.2",
    max_new_tokens=50
)

print("✅ HuggingFace Response:", response)
print("💰 Cost: FREE")
EOF

# Test the unified service
python3 << 'EOF'
import sys
sys.path.insert(0, '/mnt/e/projects/quant-discovery')

from discovery.utils.llm_service import LLMService, TaskType, ModelProvider

llm = LLMService(
    deepseek_api_key='sk-8b0ff3a7543747adb0979496981dc3c2',
    huggingface_api_key='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'
)

# Test complex reasoning (DeepSeek)
print("\n🧠 Testing Complex Reasoning (DeepSeek)...")
analysis = llm.generate(
    prompt="A politician trades every 87 days. Is this unusual? Answer in one sentence.",
    task_type=TaskType.COMPLEX_REASONING,
    max_tokens=100
)
print(f"✅ Response: {analysis}")

# Test summarization (HuggingFace)
print("\n📝 Testing Summarization (HuggingFace)...")
summary = llm.generate(
    prompt="Summarize: Pattern discovered in trading data.",
    task_type=TaskType.SUMMARIZATION,
    max_tokens=50
)
print(f"✅ Response: {summary}")

print("\n✅ All LLM providers working!")
print("💰 Total cost for these tests: <$0.001")
EOF
```

## Expected Output

```
✅ DeepSeek Response: DeepSeek is working!
💰 Cost: ~$0.000010

✅ HuggingFace Response: HuggingFace is working!
💰 Cost: FREE

🧠 Testing Complex Reasoning (DeepSeek)...
✅ Response: An 87-day trading cycle is statistically unusual and warrants investigation for potential pattern-based trading.

📝 Testing Summarization (HuggingFace)...
✅ Response: Trading pattern found in data.

✅ All LLM providers working!
💰 Total cost for these tests: <$0.001
```

## Troubleshooting

### Error: "openai module not found"
```bash
pip install openai
```

### Error: "huggingface_hub module not found"
```bash
pip install huggingface-hub
```

### Error: "Invalid API key"
```bash
# Your keys may have been rotated. Update .env with new keys.
# Get new keys:
# - DeepSeek: https://platform.deepseek.com/api_keys
# - HuggingFace: https://huggingface.co/settings/tokens
```

### Error: "Rate limit exceeded"
```bash
# HuggingFace free tier: 30K requests/month
# Upgrade to Pro ($9/month) for unlimited
```

## Cost Monitoring

Check your usage:

**DeepSeek:**
https://platform.deepseek.com/usage

**HuggingFace:**
https://huggingface.co/settings/billing

## Next Steps

Once tests pass:
1. ⚠️ **ROTATE YOUR KEYS** (they were exposed)
2. Update `.env` with new keys
3. Run discovery service: `celery -A discovery.tasks.celery_app worker -Q discovery`
4. Watch AI-generated descriptions appear!
