/**
 * Example: Testing Waterfall Enrichment
 *
 * This script demonstrates the waterfall enrichment pattern,
 * showing how providers are tried in order until data is found.
 *
 * Run with: npx tsx examples/test-enrichment.ts
 */

import { waterfallEnrich, getProviderStatus } from '../src/services/enrichment/waterfall';

async function main() {
  console.log('💎 Waterfall Enrichment Test\n');

  // Check which providers are configured
  console.log('📋 Provider Status:');
  console.log('------------------');
  const providers = getProviderStatus();
  providers.forEach(p => {
    console.log(`${p.name.padEnd(15)} - ${p.configured ? '✅ Configured' : '❌ Not configured'} (Priority: ${p.priority}, Cost: $${p.cost})`);
  });
  console.log();

  // Test cases
  const testCases = [
    {
      name: 'Lookup by email',
      input: { email: 'elon@tesla.com' },
    },
    {
      name: 'Lookup by domain',
      input: { domain: 'tesla.com', firstName: 'Elon', lastName: 'Musk' },
    },
    {
      name: 'Non-existent contact',
      input: { email: 'nonexistent@fakecompany123.com' },
    },
  ];

  for (const testCase of testCases) {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`Test: ${testCase.name}`);
    console.log(`Input: ${JSON.stringify(testCase.input)}`);
    console.log('='.repeat(60) + '\n');

    try {
      const result = await waterfallEnrich(testCase.input);

      if (result) {
        console.log('✅ Success!\n');
        console.log(`Source: ${result.source}`);
        console.log(`Confidence: ${result.confidence}%\n`);
        console.log('Data Found:');
        Object.entries(result.data).forEach(([key, value]) => {
          if (value) {
            console.log(`  ${key}: ${value}`);
          }
        });
      } else {
        console.log('❌ No data found from any provider');
      }
    } catch (error) {
      console.error('❌ Error:', error.message);
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log('💡 Tip: Configure API keys in .env to enable providers');
  console.log('='.repeat(60) + '\n');
}

main().catch(console.error);
