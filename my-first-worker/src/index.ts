import { DurableObject } from "cloudflare:workers";

/**
 * Cloud Compute Worker - Extended Edition
 *
 * This worker demonstrates offloading compute-intensive tasks to Cloudflare's edge network.
 * Features:
 * - Multiple compute endpoints (image processing, data analysis, text processing)
 * - Job queue system with Durable Objects
 * - Rate limiting and caching
 * - API key authentication
 *
 * Run `npm run dev` for local development
 * Run `npm run deploy` to publish
 */

// Types for job queue
interface Job {
	id: string;
	type: string;
	payload: any;
	status: 'pending' | 'processing' | 'completed' | 'failed';
	result?: any;
	error?: string;
	createdAt: number;
	completedAt?: number;
}

/** Durable Object for managing compute jobs and state */
export class ComputeJobQueue extends DurableObject<Env> {
	private jobs: Map<string, Job> = new Map();

	constructor(ctx: DurableObjectState, env: Env) {
		super(ctx, env);
		this.ctx.blockConcurrencyWhile(async () => {
			const stored = await this.ctx.storage.get<Map<string, Job>>('jobs');
			if (stored) {
				this.jobs = new Map(stored);
			}
		});
	}

	async sayHello(): Promise<string> {
		let result = this.ctx.storage.sql
			.exec("SELECT 'Hello, World!' as greeting")
			.one() as { greeting: string };
		return result.greeting;
	}

	async submitJob(type: string, payload: any): Promise<string> {
		const jobId = crypto.randomUUID();
		const job: Job = {
			id: jobId,
			type,
			payload,
			status: 'pending',
			createdAt: Date.now()
		};

		this.jobs.set(jobId, job);
		await this.ctx.storage.put('jobs', Array.from(this.jobs.entries()));

		// Process job asynchronously
		this.ctx.waitUntil(this.processJob(jobId));

		return jobId;
	}

	async getJob(jobId: string): Promise<Job | null> {
		return this.jobs.get(jobId) || null;
	}

	async listJobs(limit: number = 50): Promise<Job[]> {
		return Array.from(this.jobs.values())
			.sort((a, b) => b.createdAt - a.createdAt)
			.slice(0, limit);
	}

	private async processJob(jobId: string): Promise<void> {
		const job = this.jobs.get(jobId);
		if (!job) return;

		job.status = 'processing';
		await this.ctx.storage.put('jobs', Array.from(this.jobs.entries()));

		try {
			let result;
			switch (job.type) {
				case 'text-analysis':
					result = await this.analyzeText(job.payload);
					break;
				case 'data-transform':
					result = await this.transformData(job.payload);
					break;
				case 'heavy-compute':
					result = await this.heavyCompute(job.payload);
					break;
				default:
					throw new Error(`Unknown job type: ${job.type}`);
			}

			job.status = 'completed';
			job.result = result;
			job.completedAt = Date.now();
		} catch (error) {
			job.status = 'failed';
			job.error = error instanceof Error ? error.message : 'Unknown error';
			job.completedAt = Date.now();
		}

		await this.ctx.storage.put('jobs', Array.from(this.jobs.entries()));
	}

	private async analyzeText(payload: { text: string }): Promise<any> {
		const text = payload.text || '';
		if (text.length === 0) {
			return { length: 0, words: 0, sentences: 0, avgWordLength: 0, uppercaseRatio: 0 };
		}
		const words = text.split(/\s+/).filter(w => w.length > 0);
		const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
		return {
			length: text.length,
			words: words.length,
			sentences: sentences.length,
			avgWordLength: words.length > 0 ? words.reduce((sum, word) => sum + word.length, 0) / words.length : 0,
			uppercaseRatio: (text.match(/[A-Z]/g) || []).length / text.length
		};
	}

	private async transformData(payload: { data: any[], operation: string }): Promise<any> {
		const { data, operation } = payload;

		if (!Array.isArray(data)) {
			throw new Error('data must be an array');
		}

		switch (operation) {
			case 'sum':
				return { result: data.reduce((sum, n) => sum + n, 0) };
			case 'average':
				return { result: data.length > 0 ? data.reduce((sum, n) => sum + n, 0) / data.length : 0 };
			case 'sort':
				return { result: [...data].sort((a, b) => a - b) };
			case 'dedupe':
				return { result: [...new Set(data)] };
			default:
				throw new Error(`Unknown operation: ${operation}`);
		}
	}

	private async heavyCompute(payload: { iterations: number }): Promise<any> {
		const iterations = Math.min(payload.iterations, 1000000);
		let result = 0;

		for (let i = 0; i < iterations; i++) {
			result += Math.sqrt(i) * Math.sin(i);
		}

		return { result, iterations };
	}
}

// Rate limiting helper
class RateLimiter {
	private requests: Map<string, number[]> = new Map();

	isRateLimited(key: string, maxRequests: number = 100, windowMs: number = 60000): boolean {
		const now = Date.now();
		const requests = this.requests.get(key) || [];

		// Remove old requests outside the window
		const validRequests = requests.filter(time => now - time < windowMs);

		if (validRequests.length >= maxRequests) {
			return true;
		}

		validRequests.push(now);
		this.requests.set(key, validRequests);
		return false;
	}
}

const rateLimiter = new RateLimiter();

export default {
	async fetch(request, env, ctx): Promise<Response> {
		const url = new URL(request.url);
		const path = url.pathname;

		// CORS headers for browser access
		const corsHeaders = {
			'Access-Control-Allow-Origin': '*',
			'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
			'Access-Control-Allow-Headers': 'Content-Type, X-API-Key',
		};

		if (request.method === 'OPTIONS') {
			return new Response(null, { headers: corsHeaders });
		}

		// Health check (unauthenticated)
		if (path === '/health') {
			return new Response(JSON.stringify({ status: 'healthy', timestamp: Date.now() }), {
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});
		}

		// API Key authentication (use `wrangler secret put API_SECRET_KEY` to set)
		const apiKey = request.headers.get('X-API-Key');
		const secretKey = (env as any).API_SECRET_KEY as string | undefined;

		if (!secretKey || apiKey !== secretKey) {
			return new Response(JSON.stringify({ error: 'Unauthorized' }), {
				status: 401,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});
		}

		// Rate limiting
		const clientId = request.headers.get('CF-Connecting-IP') || 'unknown';
		if (rateLimiter.isRateLimited(clientId)) {
			return new Response(JSON.stringify({ error: 'Rate limit exceeded' }), {
				status: 429,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});
		}

		try {
			// Route to appropriate handler
			if (path === '/' || path === '/hello') {
				return await handleHello(request, env, corsHeaders);
			} else if (path.startsWith('/compute/')) {
				return await handleCompute(request, env, path, corsHeaders);
			} else if (path.startsWith('/jobs')) {
				return await handleJobs(request, env, path, corsHeaders);
			} else {
				return new Response(JSON.stringify({ error: 'Not Found' }), {
					status: 404,
					headers: { ...corsHeaders, 'Content-Type': 'application/json' }
				});
			}
		} catch (error) {
			return new Response(JSON.stringify({
				error: 'Internal Server Error',
				message: error instanceof Error ? error.message : 'Unknown error'
			}), {
				status: 500,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});
		}
	},
} satisfies ExportedHandler<Env>;

// Handler functions
async function handleHello(request: Request, env: Env, corsHeaders: any): Promise<Response> {
	const id: DurableObjectId = env.MY_DURABLE_OBJECT.idFromName('hello');
	const stub = env.MY_DURABLE_OBJECT.get(id);
	const greeting = await stub.sayHello();

	return new Response(JSON.stringify({ message: greeting, timestamp: Date.now() }), {
		headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	});
}

async function handleCompute(request: Request, env: Env, path: string, corsHeaders: any): Promise<Response> {
	const segments = path.split('/').filter(Boolean);
	const computeType = segments[1];

	if (request.method !== 'POST') {
		return new Response(JSON.stringify({ error: 'Method not allowed' }), {
			status: 405,
			headers: { ...corsHeaders, 'Content-Type': 'application/json' }
		});
	}

	let body: any;
	try {
		body = await request.json();
	} catch {
		return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
			status: 400,
			headers: { ...corsHeaders, 'Content-Type': 'application/json' }
		});
	}

	// Immediate compute (synchronous)
	switch (computeType) {
		case 'hash':
			const text = body.text || '';
			const encoder = new TextEncoder();
			const data = encoder.encode(text);
			const hashBuffer = await crypto.subtle.digest('SHA-256', data);
			const hashArray = Array.from(new Uint8Array(hashBuffer));
			const hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
			return new Response(JSON.stringify({ hash, length: text.length }), {
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});

		case 'base64':
			const operation = body.operation || 'encode';
			const input = body.input || '';
			let result;
			if (operation === 'encode') {
				result = btoa(input);
			} else {
				result = atob(input);
			}
			return new Response(JSON.stringify({ result, operation }), {
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});

		case 'json-transform':
			const data_input = body.data || [];
			const transform = body.transform || 'stringify';
			let transformed;
			if (transform === 'stringify') {
				transformed = JSON.stringify(data_input, null, 2);
			} else if (transform === 'flatten') {
				transformed = flattenObject(data_input);
			} else {
				throw new Error('Unknown transform');
			}
			return new Response(JSON.stringify({ result: transformed }), {
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});

		default:
			return new Response(JSON.stringify({ error: 'Unknown compute type' }), {
				status: 400,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});
	}
}

async function handleJobs(request: Request, env: Env, path: string, corsHeaders: any): Promise<Response> {
	const id: DurableObjectId = env.MY_DURABLE_OBJECT.idFromName('job-queue');
	const stub = env.MY_DURABLE_OBJECT.get(id);

	const segments = path.split('/').filter(Boolean);

	if (request.method === 'POST' && segments.length === 1) {
		// Submit new job
		let body: any;
		try {
			body = await request.json();
		} catch {
			return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
				status: 400,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});
		}
		if (!body.type) {
			return new Response(JSON.stringify({ error: 'Missing required field: type' }), {
				status: 400,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});
		}
		const jobId = await stub.submitJob(body.type, body.payload);
		return new Response(JSON.stringify({ jobId, status: 'submitted' }), {
			headers: { ...corsHeaders, 'Content-Type': 'application/json' }
		});
	} else if (request.method === 'GET' && segments.length === 2) {
		// Get specific job
		const jobId = segments[1];
		const job = await stub.getJob(jobId);
		if (!job) {
			return new Response(JSON.stringify({ error: 'Job not found' }), {
				status: 404,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' }
			});
		}
		return new Response(JSON.stringify(job), {
			headers: { ...corsHeaders, 'Content-Type': 'application/json' }
		});
	} else if (request.method === 'GET' && segments.length === 1) {
		// List all jobs
		const jobs = await stub.listJobs(50);
		return new Response(JSON.stringify({ jobs, count: jobs.length }), {
			headers: { ...corsHeaders, 'Content-Type': 'application/json' }
		});
	} else {
		return new Response(JSON.stringify({ error: 'Invalid request' }), {
			status: 400,
			headers: { ...corsHeaders, 'Content-Type': 'application/json' }
		});
	}
}

function flattenObject(obj: any, prefix = ''): any {
	const flattened: any = {};

	for (const [key, value] of Object.entries(obj)) {
		const newKey = prefix ? `${prefix}.${key}` : key;

		if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
			Object.assign(flattened, flattenObject(value, newKey));
		} else {
			flattened[newKey] = value;
		}
	}

	return flattened;
}
