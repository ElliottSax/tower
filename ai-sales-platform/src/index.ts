import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import path from 'path';
import { config, validateConfig } from './config';
import { supervisorAgent } from './agents/supervisor';
import { initSentry, captureException, startTransaction } from './lib/sentry';
import businessRoutes from './api/businesses';

/**
 * AI Sales Platform - Main Entry Point
 *
 * This is a minimal API server to demonstrate the AI orchestration layer.
 * In production, you would add:
 * - Full authentication middleware
 * - Complete CRUD endpoints for campaigns, leads, etc.
 * - Background job processing with BullMQ
 * - WebSocket support for real-time updates
 * - Comprehensive error handling
 * - Monitoring and logging
 */

async function main() {
  // Initialize Sentry for error monitoring
  initSentry();

  // Validate configuration
  validateConfig();

  const app = express();

  // Middleware
  app.use(helmet());
  app.use(cors());
  app.use(express.json());

  // Health check
  app.get('/health', (req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
    });
  });

  // ============================================
  // AI Agent Demo Endpoint
  // ============================================

  /**
   * POST /api/agent/execute
   *
   * Execute an AI agent workflow
   *
   * Body:
   * {
   *   "task": {
   *     "type": "personalize",
   *     "input": { ... }
   *   },
   *   "lead": {
   *     "email": "john@example.com",
   *     "firstName": "John",
   *     "companyName": "Example Corp",
   *     "companyDomain": "example.com"
   *   }
   * }
   */
  app.post('/api/agent/execute', async (req, res) => {
    const transaction = startTransaction('agent.execute', 'http');

    try {
      const { task, lead } = req.body;

      // In production, get tenantId from authenticated user
      const tenantId = 'demo-tenant';

      console.log(`\n========================================`);
      console.log(`Executing AI Agent Workflow`);
      console.log(`Task: ${task.type}`);
      console.log(`Lead: ${lead.firstName} @ ${lead.companyName}`);
      console.log(`========================================\n`);

      // Execute the multi-agent workflow
      const result = await supervisorAgent.execute({
        tenantId,
        task,
        lead,
      });

      console.log(`\n========================================`);
      console.log(`Workflow Complete`);
      console.log(`Final State: ${result.nextAgent}`);
      console.log(`Errors: ${result.errors?.length || 0}`);
      console.log(`========================================\n`);

      res.json({
        success: true,
        sessionId: result.sessionId,
        result: {
          research: result.research,
          enrichment: result.enrichment,
          personalization: result.personalization,
          errors: result.errors,
        },
      });

      transaction.setStatus('ok');
    } catch (error) {
      console.error('Agent execution error:', error);
      captureException(error as Error, {
        task: req.body.task,
        lead: req.body.lead?.email,
      });

      transaction.setStatus('internal_error');

      res.status(500).json({
        success: false,
        error: (error as Error).message,
      });
    } finally {
      transaction.finish();
    }
  });

  // ============================================
  // Example: Simple Lead Enrichment Endpoint
  // ============================================

  /**
   * POST /api/leads/enrich
   *
   * Enrich a lead using waterfall enrichment
   */
  app.post('/api/leads/enrich', async (req, res) => {
    try {
      const { email, domain } = req.body;

      if (!email && !domain) {
        return res.status(400).json({
          error: 'Either email or domain is required',
        });
      }

      const { waterfallEnrich } = await import('./services/enrichment/waterfall');

      const result = await waterfallEnrich({ email, domain });

      if (!result) {
        return res.status(404).json({
          error: 'No enrichment data found',
        });
      }

      res.json({
        success: true,
        data: result,
      });
    } catch (error: any) {
      console.error('Enrichment error:', error);
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  });

  // ============================================
  // Example: AI Email Generation Endpoint
  // ============================================

  /**
   * POST /api/emails/generate
   *
   * Generate a personalized email using AI
   */
  app.post('/api/emails/generate', async (req, res) => {
    try {
      const { lead, research, customInstructions } = req.body;

      if (!lead?.firstName || !lead?.companyName) {
        return res.status(400).json({
          error: 'Lead must include firstName and companyName',
        });
      }

      // Execute just the writer agent
      const result = await supervisorAgent.execute({
        tenantId: 'demo-tenant',
        task: {
          type: 'personalize',
          input: { customInstructions },
        },
        lead,
      });

      if (!result.personalization) {
        return res.status(500).json({
          error: 'Failed to generate email',
          errors: result.errors,
        });
      }

      res.json({
        success: true,
        email: result.personalization,
      });
    } catch (error: any) {
      console.error('Email generation error:', error);
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  });

  // ============================================
  // Business Management API (Polsia Clone)
  // ============================================
  app.use('/api/businesses', businessRoutes);

  // ============================================
  // Dashboard (served as static HTML)
  // ============================================
  app.use('/dashboard', express.static(path.join(__dirname, 'dashboard')));
  app.get('/', (req, res) => {
    res.redirect('/dashboard');
  });

  // Error handling middleware
  app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
    console.error('Unhandled error:', err);

    // Capture error in Sentry
    captureException(err, {
      url: req.url,
      method: req.method,
      body: req.body,
    });

    res.status(500).json({
      error: 'Internal server error',
      message: config.nodeEnv === 'development' ? err.message : undefined,
    });
  });

  // Start server
  const server = app.listen(config.port, () => {
    console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     Autonomous Business Platform - Running                ║
║     "Polsia Done Right"                                   ║
║                                                           ║
║  Port:        ${config.port}                                        ║
║  Environment: ${config.nodeEnv}                              ║
║                                                           ║
║  Dashboard:   http://localhost:${config.port}/dashboard              ║
║                                                           ║
║  API Endpoints:                                           ║
║    GET  /health                                           ║
║    GET  /api/businesses                                   ║
║    POST /api/businesses                                   ║
║    GET  /api/businesses/:id                               ║
║    GET  /api/businesses/:id/logs                          ║
║    POST /api/businesses/:id/resume                        ║
║    GET  /api/businesses/stats/overview                    ║
║    POST /api/agent/execute                                ║
║    POST /api/leads/enrich                                 ║
║    POST /api/emails/generate                              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    `);
  });

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    console.log('SIGTERM received, shutting down gracefully...');

    // Flush Sentry events before shutdown
    await import('./lib/sentry').then(({ flushSentry }) => flushSentry());

    server.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
  });
}

main().catch((error) => {
  console.error('Fatal error:', error);
  captureException(error);
  process.exit(1);
});
