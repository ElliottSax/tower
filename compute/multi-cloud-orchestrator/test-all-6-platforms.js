/**
 * Test ALL 6 Working Platforms
 */

const config = require('./config');

console.log('🧪 TESTING ALL 6 WORKING AI PLATFORMS\n');
console.log('═'.repeat(60));

async function testPlatform(name, apiCall) {
  console.log(`\n${name}`);
  console.log('─'.repeat(60));
  try {
    const start = Date.now();
    const result = await apiCall();
    const duration = Date.now() - start;
    console.log(`✅ WORKING - ${duration}ms`);
    console.log(`   Response: ${result.substring(0, 60)}...`);
    return true;
  } catch (error) {
    console.log(`❌ FAILED: ${error.message.substring(0, 80)}`);
    return false;
  }
}

async function main() {
  const results = {};

  // 1. Groq
  results.groq = await testPlatform('1️⃣  GROQ (Ultra-fast, FREE)', async () => {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.groq.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [{ role: 'user', content: 'Hi' }],
        max_tokens: 20
      })
    });
    const data = await res.json();
    return data.choices[0].message.content;
  });

  // 2. DeepSeek
  results.deepseek = await testPlatform('2️⃣  DEEPSEEK (Code specialist)', async () => {
    const res = await fetch('https://api.deepseek.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.deepseek.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'deepseek-chat',
        messages: [{ role: 'user', content: 'Hi' }],
        max_tokens: 20
      })
    });
    const data = await res.json();
    return data.choices[0].message.content;
  });

  // 3. Cerebras
  results.cerebras = await testPlatform('3️⃣  CEREBRAS (Custom chips)', async () => {
    const res = await fetch('https://api.cerebras.ai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.cerebras.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'llama3.1-8b',
        messages: [{ role: 'user', content: 'Hi' }],
        max_tokens: 20
      })
    });
    const data = await res.json();
    return data.choices[0].message.content;
  });

  // 4. Together
  results.together = await testPlatform('4️⃣  TOGETHER AI (Multi-model)', async () => {
    const res = await fetch('https://api.together.xyz/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.together.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'meta-llama/Llama-3.2-3B-Instruct-Turbo',
        messages: [{ role: 'user', content: 'Hi' }],
        max_tokens: 20
      })
    });
    const data = await res.json();
    return data.choices[0].message.content;
  });

  // 5. Replicate
  results.replicate = await testPlatform('5️⃣  REPLICATE (ML models)', async () => {
    const res = await fetch('https://api.replicate.com/v1/models', {
      headers: { 'Authorization': `Bearer ${config.replicate.apiKey}` }
    });
    const data = await res.json();
    return `${data.results.length} models available`;
  });

  // 6. OpenRouter (NEW!)
  results.openrouter = await testPlatform('6️⃣  OPENROUTER (100+ models) ⭐ NEW', async () => {
    const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.openrouter.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'meta-llama/llama-3.1-8b-instruct',
        messages: [{ role: 'user', content: 'Hi' }],
        max_tokens: 20
      })
    });
    const data = await res.json();
    return data.choices[0].message.content;
  });

  // Summary
  console.log('\n' + '═'.repeat(60));
  console.log('\n📊 SUMMARY\n');

  const working = Object.values(results).filter(r => r === true).length;
  const total = Object.keys(results).length;

  for (const [platform, status] of Object.entries(results)) {
    const icon = status ? '✅' : '❌';
    console.log(`${icon} ${platform.toUpperCase()}`);
  }

  console.log(`\n🎯 ${working}/${total} platforms operational\n`);

  if (working === total) {
    console.log('🎉 ALL 6 PLATFORMS CONFIRMED WORKING! 🚀\n');
    console.log('You now have 6 AI platforms with intelligent orchestration!\n');
  } else {
    console.log(`Working: ${working} platforms`);
    console.log(`Failed: ${total - working} platforms\n`);
  }
}

main().catch(console.error);
