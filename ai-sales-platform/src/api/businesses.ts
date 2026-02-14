import { Router, Request, Response } from 'express';
import { createOrchestrator, AutonomousBusinessOrchestrator } from '../autonomous/orchestrator';
import { BusinessIdea } from '../autonomous/types';
import { captureException, addBreadcrumb } from '../lib/sentry';

/**
 * Business Management API Routes
 *
 * Provides endpoints for:
 * - Launching new businesses
 * - Viewing business status
 * - Listing all businesses
 * - Resuming paused workflows
 * - Agent activity logs
 * - Cost tracking
 */

const router = Router();

// In-memory store for sessions (in production, use database)
const businessSessions = new Map<string, {
  sessionId: string;
  businessName: string;
  idea: BusinessIdea;
  status: 'running' | 'paused' | 'completed' | 'failed';
  createdAt: string;
  updatedAt: string;
  phase: string;
  totalCost: number;
  estimatedMonthlyCost: number;
  completedTasks: number;
  pendingTasks: number;
  errors: string[];
  agentLogs: Array<{
    timestamp: string;
    agent: string;
    action: string;
    details?: string;
  }>;
}>();

let orchestrator: AutonomousBusinessOrchestrator | null = null;

function getOrchestrator(): AutonomousBusinessOrchestrator | null {
  if (!orchestrator && process.env.DATABASE_URL) {
    orchestrator = createOrchestrator(process.env.DATABASE_URL);
  }
  return orchestrator;
}

/**
 * POST /api/businesses
 * Launch a new autonomous business
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const { idea, businessName } = req.body;

    if (!idea?.description || !idea?.targetMarket || !idea?.problemSolved) {
      res.status(400).json({
        error: 'Missing required fields: idea.description, idea.targetMarket, idea.problemSolved',
      });
      return;
    }

    const sessionId = crypto.randomUUID();
    const tenantId = req.headers['x-tenant-id'] as string || 'default';

    // Create session record
    const session = {
      sessionId,
      businessName: businessName || 'Untitled Business',
      idea: idea as BusinessIdea,
      status: 'running' as const,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      phase: 'validation',
      totalCost: 0,
      estimatedMonthlyCost: 700,
      completedTasks: 0,
      pendingTasks: 0,
      errors: [],
      agentLogs: [{
        timestamp: new Date().toISOString(),
        agent: 'system',
        action: 'Business launch initiated',
        details: `Business: ${businessName || 'Untitled'}, Idea: ${idea.description}`,
      }],
    };

    businessSessions.set(sessionId, session);

    // Try to launch with orchestrator if database available
    const orch = getOrchestrator();
    if (orch) {
      // Launch async - don't await
      orch.launchBusiness({ tenantId, idea, businessName }).then(result => {
        const existing = businessSessions.get(sessionId);
        if (existing) {
          existing.status = result.errors?.length ? 'failed' : 'completed';
          existing.phase = result.currentPhase;
          existing.totalCost = result.totalCost || 0;
          existing.estimatedMonthlyCost = result.estimatedMonthlyCost || 700;
          existing.completedTasks = result.completedTasks?.length || 0;
          existing.pendingTasks = result.pendingTasks?.length || 0;
          existing.errors = result.errors || [];
          existing.updatedAt = new Date().toISOString();
        }
      }).catch(err => {
        const existing = businessSessions.get(sessionId);
        if (existing) {
          existing.status = 'failed';
          existing.errors.push(err.message);
          existing.updatedAt = new Date().toISOString();
        }
      });
    } else {
      // Simulate completion without database
      session.agentLogs.push({
        timestamp: new Date().toISOString(),
        agent: 'system',
        action: 'Running in demo mode (no DATABASE_URL)',
      });

      // Simulate agent progression
      simulateAgentProgress(sessionId);
    }

    res.status(201).json({
      success: true,
      sessionId,
      message: 'Business launch initiated',
      status: session.status,
    });
  } catch (error: any) {
    captureException(error, { route: 'POST /api/businesses' });
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/businesses
 * List all businesses
 */
router.get('/', (req: Request, res: Response) => {
  const businesses = Array.from(businessSessions.values()).map(session => ({
    sessionId: session.sessionId,
    businessName: session.businessName,
    status: session.status,
    phase: session.phase,
    totalCost: session.totalCost,
    estimatedMonthlyCost: session.estimatedMonthlyCost,
    completedTasks: session.completedTasks,
    pendingTasks: session.pendingTasks,
    createdAt: session.createdAt,
    updatedAt: session.updatedAt,
    hasErrors: session.errors.length > 0,
  }));

  res.json({
    success: true,
    count: businesses.length,
    businesses,
  });
});

/**
 * GET /api/businesses/:id
 * Get business details
 */
router.get('/:id', (req: Request, res: Response) => {
  const session = businessSessions.get(req.params.id);

  if (!session) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  res.json({
    success: true,
    business: session,
  });
});

/**
 * GET /api/businesses/:id/logs
 * Get agent activity logs for a business
 */
router.get('/:id/logs', (req: Request, res: Response) => {
  const session = businessSessions.get(req.params.id);

  if (!session) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  const limit = parseInt(req.query.limit as string) || 50;
  const offset = parseInt(req.query.offset as string) || 0;

  const logs = session.agentLogs.slice(offset, offset + limit);

  res.json({
    success: true,
    total: session.agentLogs.length,
    logs,
  });
});

/**
 * POST /api/businesses/:id/resume
 * Resume a paused workflow
 */
router.post('/:id/resume', async (req: Request, res: Response) => {
  const session = businessSessions.get(req.params.id);

  if (!session) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  if (session.status !== 'paused') {
    res.status(400).json({ error: `Cannot resume business in ${session.status} status` });
    return;
  }

  const orch = getOrchestrator();
  if (!orch) {
    res.status(503).json({ error: 'Orchestrator not available (no DATABASE_URL)' });
    return;
  }

  try {
    session.status = 'running';
    session.updatedAt = new Date().toISOString();
    session.agentLogs.push({
      timestamp: new Date().toISOString(),
      agent: 'system',
      action: 'Workflow resumed',
    });

    const result = await orch.resumeWorkflow(req.params.id, req.body.decision);

    session.status = result.nextAgent === 'END' ? 'completed' : 'paused';
    session.phase = result.currentPhase;
    session.updatedAt = new Date().toISOString();

    res.json({ success: true, business: session });
  } catch (error: any) {
    session.status = 'failed';
    session.errors.push(error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * DELETE /api/businesses/:id
 * Remove a business
 */
router.delete('/:id', (req: Request, res: Response) => {
  if (!businessSessions.has(req.params.id)) {
    res.status(404).json({ error: 'Business not found' });
    return;
  }

  businessSessions.delete(req.params.id);
  res.json({ success: true, message: 'Business removed' });
});

/**
 * GET /api/stats
 * Get platform statistics
 */
router.get('/stats/overview', (req: Request, res: Response) => {
  const sessions = Array.from(businessSessions.values());

  const stats = {
    totalBusinesses: sessions.length,
    running: sessions.filter(s => s.status === 'running').length,
    completed: sessions.filter(s => s.status === 'completed').length,
    failed: sessions.filter(s => s.status === 'failed').length,
    paused: sessions.filter(s => s.status === 'paused').length,
    totalCost: sessions.reduce((sum, s) => sum + s.totalCost, 0),
    totalCompletedTasks: sessions.reduce((sum, s) => sum + s.completedTasks, 0),
    avgMonthlyCost: sessions.length
      ? sessions.reduce((sum, s) => sum + s.estimatedMonthlyCost, 0) / sessions.length
      : 0,
  };

  res.json({ success: true, stats });
});

/**
 * Simulate agent progression (demo mode without database)
 */
function simulateAgentProgress(sessionId: string) {
  const session = businessSessions.get(sessionId);
  if (!session) return;

  const agents = [
    { agent: 'CEO Agent', action: 'Analyzing business idea', delay: 500 },
    { agent: 'Formation Advisor', action: 'Recommending: Sole proprietorship (save $399!)', delay: 1000 },
    { agent: 'Product Manager', action: 'Defining MVP specifications', delay: 1500 },
    { agent: 'Developer Worker', action: 'Generating code (simulation mode)', delay: 2500 },
    { agent: 'Payment Setup Worker', action: 'Configuring Stripe payments', delay: 3000 },
    { agent: 'Marketing Manager', action: 'Creating marketing strategy', delay: 3500 },
    { agent: 'Content Worker', action: 'Generating landing page copy', delay: 4000 },
    { agent: 'Ads Worker', action: 'Creating Meta + Google campaigns (simulation)', delay: 4500 },
    { agent: 'Operations Manager', action: 'Planning support setup', delay: 5000 },
    { agent: 'Support Worker', action: 'Setting up Chatwoot (simulation)', delay: 5500 },
    { agent: 'Finance Manager', action: 'Configuring bookkeeping', delay: 6000 },
    { agent: 'Bookkeeper Worker', action: 'Creating spreadsheet template', delay: 6500 },
    { agent: 'CEO Agent', action: 'Business launch workflow completed', delay: 7000 },
  ];

  agents.forEach(({ agent, action, delay }, index) => {
    setTimeout(() => {
      const s = businessSessions.get(sessionId);
      if (!s) return;

      s.agentLogs.push({
        timestamp: new Date().toISOString(),
        agent,
        action,
      });
      s.completedTasks = index + 1;
      s.updatedAt = new Date().toISOString();

      // Update phase based on progress
      if (index < 2) s.phase = 'validation';
      else if (index < 5) s.phase = 'product';
      else if (index < 9) s.phase = 'marketing';
      else if (index < 11) s.phase = 'operations';
      else {
        s.phase = 'completed';
        s.status = 'completed';
        s.totalCost = 1020;
        s.estimatedMonthlyCost = 1020;
      }
    }, delay);
  });
}

export default router;
