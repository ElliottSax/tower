/**
 * Test ALL Cloud Platforms
 *
 * Tests Cloudflare, GCP, Hugging Face, DeepSeek, and all other configured providers
 */

const config = require('./config');

console.log('🧪 TESTING ALL CLOUD PLATFORMS\n');
console.log('═'.repeat(60));

async function testCloudflare() {
  console.log('\n1️⃣  CLOUDFLARE WORKERS');
  console.log('─'.repeat(60));

  try {
    const response = await fetch(config.cloudflare.apiUrl + '/compute/hash', {
      method: 'POST',
      headers: {
        'X-API-Key': config.cloudflare.apiKey,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ text: 'Testing Cloudflare!' })
    });

    const result = await response.json();
    console.log('✅ Cloudflare Workers LIVE');
    console.log(`   Hash: ${result.hash?.substring(0, 16)}...`);
    console.log(`   Status: ${response.status}`);
    return true;
  } catch (error) {
    console.log('❌ Cloudflare error:', error.message);
    return false;
  }
}

async function testHuggingFace() {
  console.log('\n2️⃣  HUGGING FACE AI');
  console.log('─'.repeat(60));

  if (!config.huggingface.enabled) {
    console.log('⊘  Disabled in config');
    return false;
  }

  try {
    const response = await fetch(
      'https://router.huggingface.co/models/distilbert-base-uncased-finetuned-sst-2-english',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${config.huggingface.apiKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ inputs: 'I love cloud computing!' })
      }
    );

    const result = await response.json();
    console.log('✅ Hugging Face API WORKING');
    console.log(`   Result:`, result);
    return true;
  } catch (error) {
    console.log('❌ Hugging Face error:', error.message);
    return false;
  }
}

async function testDeepSeek() {
  console.log('\n3️⃣  DEEPSEEK AI');
  console.log('─'.repeat(60));

  if (!config.deepseek.enabled) {
    console.log('⊘  Disabled in config');
    return false;
  }

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
    console.log(`   Response: ${result.choices[0].message.content.substring(0, 100)}...`);
    console.log(`   Tokens used: ${result.usage.total_tokens}`);
    return true;
  } catch (error) {
    console.log('❌ DeepSeek error:', error.message);
    return false;
  }
}

async function testGCP() {
  console.log('\n4️⃣  GOOGLE CLOUD FUNCTIONS');
  console.log('─'.repeat(60));

  if (!config.gcp.enabled) {
    console.log('⊘  Disabled in config');
    return false;
  }

  console.log('⏳ Checking deployment...');
  console.log('   Run: gcloud functions list --project=' + config.gcp.projectId);

  // GCP endpoints will be added after deployment
  if (config.gcp.endpoints.hash) {
    try {
      const response = await fetch(config.gcp.endpoints.hash, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: 'Testing GCP!' })
      });

      const result = await response.json();
      console.log('✅ GCP Functions LIVE');
      console.log(`   Hash: ${result.hash?.substring(0, 16)}...`);
      return true;
    } catch (error) {
      console.log('❌ GCP error:', error.message);
      return false;
    }
  } else {
    console.log('⏳ Deployment in progress...');
    return false;
  }
}

async function testGroq() {
  console.log('\n5️⃣  GROQ (Ultra-fast inference)');
  console.log('─'.repeat(60));

  if (!config.groq?.enabled) {
    console.log('⊘  Disabled in config');
    return false;
  }

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.groq.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'mixtral-8x7b-32768',
        messages: [{ role: 'user', content: 'Say hi' }],
        max_tokens: 50
      })
    });

    const result = await response.json();
    console.log('✅ Groq API WORKING');
    console.log(`   Response: ${result.choices?.[0].message.content.substring(0, 50)}...`);
    return true;
  } catch (error) {
    console.log('❌ Groq error:', error.message);
    return false;
  }
}

async function main() {
  const results = {
    cloudflare: await testCloudflare(),
    huggingface: await testHuggingFace(),
    deepseek: await testDeepSeek(),
    gcp: await testGCP(),
    groq: await testGroq()
  };

  console.log('\n═'.repeat(60));
  console.log('\n📊 SUMMARY\n');

  const working = Object.values(results).filter(r => r === true).length;
  const total = Object.keys(results).length;

  for (const [platform, status] of Object.entries(results)) {
    const icon = status ? '✅' : '❌';
    console.log(`${icon} ${platform.toUpperCase()}: ${status ? 'WORKING' : 'NOT READY'}`);
  }

  console.log(`\n🎯 ${working}/${total} platforms operational\n`);

  if (working === total) {
    console.log('🎉 ALL PLATFORMS WORKING! You have full multi-cloud compute! 🚀\n');
  } else {
    console.log('⏳ Some platforms still deploying...\n');
  }
}

main().catch(console.error);
