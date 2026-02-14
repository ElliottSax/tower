import * as Sentry from '@sentry/node';
import { config } from '../config';

/**
 * Sentry Configuration for Autonomous Business Platform
 *
 * Monitors errors, performance, and provides distributed tracing
 * across the multi-agent AI system.
 */

let sentryInitialized = false;

export function initSentry() {
  if (!process.env.SENTRY_DSN) {
    console.warn('Sentry DSN not configured - error monitoring disabled');
    return;
  }

  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: config.nodeEnv,
    tracesSampleRate: config.nodeEnv === 'production' ? 0.1 : 1.0,
    profilesSampleRate: config.nodeEnv === 'production' ? 0.1 : 1.0,
    release: process.env.npm_package_version || '1.0.0',
    ignoreErrors: [
      /^Non-Error promise rejection captured/,
      /^Non-Error exception captured/,
    ],
    initialScope: {
      tags: {
        service: 'autonomous-business-platform',
        component: 'backend',
      },
    },
    beforeSend(event) {
      if (event.request) {
        delete event.request.cookies;
      }
      event.tags = {
        ...event.tags,
        node_version: process.version,
      };
      return event;
    },
  });

  sentryInitialized = true;
  console.log('Sentry initialized for error monitoring');
}

export function captureException(error: Error, context?: Record<string, any>) {
  if (!sentryInitialized) return;

  if (context) {
    Sentry.withScope((scope) => {
      Object.entries(context).forEach(([key, value]) => {
        scope.setContext(key, value);
      });
      Sentry.captureException(error);
    });
  } else {
    Sentry.captureException(error);
  }
}

export function captureMessage(message: string, level: Sentry.SeverityLevel = 'info') {
  if (!sentryInitialized) return;
  Sentry.captureMessage(message, level);
}

export function startTransaction(name: string, op: string) {
  // Sentry v8+ uses spans instead of transactions
  // Return a compatible interface for the existing code
  return {
    setStatus: (_status: string) => {},
    finish: () => {},
  };
}

export function addBreadcrumb(breadcrumb: Sentry.Breadcrumb) {
  if (!sentryInitialized) return;
  Sentry.addBreadcrumb(breadcrumb);
}

export function setUser(user: { id: string; email?: string; username?: string }) {
  if (!sentryInitialized) return;
  Sentry.setUser(user);
}

export function clearUser() {
  if (!sentryInitialized) return;
  Sentry.setUser(null);
}

export function setTag(key: string, value: string) {
  if (!sentryInitialized) return;
  Sentry.setTag(key, value);
}

export async function flushSentry(timeout = 2000): Promise<boolean> {
  if (!sentryInitialized) return true;
  return Sentry.close(timeout);
}
