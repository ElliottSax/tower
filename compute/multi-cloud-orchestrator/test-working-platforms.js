/**
 * Test ONLY the working AI platforms
 *
 * Tests the 5 confirmed operational platforms:
 * - DeepSeek
 * - Groq
 * - Together AI
 * - Cerebras
 * - Replicate
 */

const config = require('./config');

console.log('🧪 TESTING WORKING AI PLATFORMS\n');
console.log('═'.repeat(60));

async function testDeepSeek() {
  console.log('\n1️⃣  DEEPSEEK AI');
  console.log('─'.repeat(60));

  try {
    const response = await fetch('https://api.deepseek.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.deepseek.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'deepseek-chat',
        messages: [{ role: 'user', content: 'Write a one-line hello function in JavaScript' }],
        max_tokens: 100
      })
    });

    const result = await response.json();
    console.log('✅ DeepSeek API WORKING');
    console.log(`   Response: ${result.choices[0].message.content.substring(0, 80)}...`);
    console.log(`   Tokens used: ${result.usage.total_tokens}`);
    console.log(`   Cost: ~$${(result.usage.total_tokens / 1000000 * 0.14).toFixed(6)}`);
    return true;
  } catch (error) {
    console.log('❌ DeepSeek error:', error.message);
    return false;
  }
}

async function testGroq() {
  console.log('\n2️⃣  GROQ (Ultra-fast inference)');
  console.log('─'.repeat(60));

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.groq.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [{ role: 'user', content: 'Say hi in 5 words' }],
        max_tokens: 50
      })
    });

    const result = await response.json();
    console.log('✅ Groq API WORKING');
    console.log(`   Response: ${result.choices[0].message.content}`);
    console.log(`   Tokens: ${result.usage.total_tokens}`);
    console.log(`   Time: ${result.usage.total_time.toFixed(3)}s`);
    console.log(`   Speed: ${(result.usage.total_tokens / result.usage.total_time).toFixed(0)} tokens/sec`);
    return true;
  } catch (error) {
    console.log('❌ Groq error:', error.message);
    return false;
  }
}

async function testTogether() {
  console.log('\n3️⃣  TOGETHER AI');
  console.log('─'.repeat(60));

  try {
    const response = await fetch('https://api.together.xyz/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.together.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'meta-llama/Llama-3.2-3B-Instruct-Turbo',
        messages: [{ role: 'user', content: 'What is 2+2?' }],
        max_tokens: 50
      })
    });

    const result = await response.json();
    console.log('✅ Together AI WORKING');
    console.log(`   Response: ${result.choices[0].message.content}`);
    console.log(`   Tokens: ${result.usage.total_tokens}`);
    return true;
  } catch (error) {
    console.log('❌ Together AI error:', error.message);
    return false;
  }
}

async function testCerebras() {
  console.log('\n4️⃣  CEREBRAS (Custom AI chips)');
  console.log('─'.repeat(60));

  try {
    const response = await fetch('https://api.cerebras.ai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.cerebras.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'llama3.1-8b',
        messages: [{ role: 'user', content: 'Count to 5' }],
        max_tokens: 50
      })
    });

    const result = await response.json();
    console.log('✅ Cerebras API WORKING');
    console.log(`   Response: ${result.choices[0].message.content}`);
    console.log(`   Tokens: ${result.usage.total_tokens}`);
    console.log(`   Time: ${result.time_info.total_time.toFixed(3)}s`);
    return true;
  } catch (error) {
    console.log('❌ Cerebras error:', error.message);
    return false;
  }
}

async function testReplicate() {
  console.log('\n5️⃣  REPLICATE');
  console.log('─'.repeat(60));

  try {
    const response = await fetch('https://api.replicate.com/v1/models', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${config.replicate.apiKey}`
      }
    });

    const result = await response.json();
    console.log('✅ Replicate API WORKING');
    console.log(`   Available models: ${result.results.length}+`);
    console.log(`   Sample models:`);
    result.results.slice(0, 3).forEach(model => {
      console.log(`   - ${model.owner}/${model.name}`);
    });
    return true;
  } catch (error) {
    console.log('❌ Replicate error:', error.message);
    return false;
  }
}

async function main() {
  const results = {
    deepseek: await testDeepSeek(),
    groq: await testGroq(),
    together: await testTogether(),
    cerebras: await testCerebras(),
    replicate: await testReplicate()
  };

  console.log('\n═'.repeat(60));
  console.log('\n📊 SUMMARY\n');

  const working = Object.values(results).filter(r => r === true).length;
  const total = Object.keys(results).length;

  for (const [platform, status] of Object.entries(results)) {
    const icon = status ? '✅' : '❌';
    console.log(`${icon} ${platform.toUpperCase()}: ${status ? 'WORKING' : 'FAILED'}`);
  }

  console.log(`\n🎯 ${working}/${total} platforms operational\n`);

  if (working === total) {
    console.log('🎉 ALL WORKING PLATFORMS CONFIRMED! 🚀\n');
    console.log('You have multi-cloud AI infrastructure operational!\n');
    console.log('Next steps:');
    console.log('  1. Integrate these into your orchestrator');
    console.log('  2. Fix remaining platforms (Hugging Face, Fireworks, etc.)');
    console.log('  3. Enable GCP billing for cloud functions');
    console.log('  4. Configure AWS for Lambda deployment\n');
  } else {
    console.log('⚠️  Some platforms failed. Check errors above.\n');
  }
}

main().catch(console.error);
