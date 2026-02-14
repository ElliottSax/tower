"""Celery application configuration for discovery service."""

from celery import Celery
from celery.schedules import crontab

from discovery.core.config import settings

# Create Celery app
celery_app = Celery(
    'discovery',
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
)

# Celery configuration
celery_app.conf.update(
    # Serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    result_expires=3600 * 24,  # 24 hours

    # Timezone
    timezone='UTC',
    enable_utc=True,

    # Task execution
    task_track_started=True,
    task_time_limit=3600 * 12,  # 12 hours max
    task_soft_time_limit=3600 * 10,  # 10 hours soft limit
    task_acks_late=True,
    task_reject_on_worker_lost=True,

    # Worker configuration
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=10,  # Restart worker after 10 tasks (prevent memory leaks)
    worker_disable_rate_limits=False,

    # Results
    result_backend_transport_options={
        'master_name': 'mymaster',
    },
)

# Scheduled tasks (Celery Beat)
celery_app.conf.beat_schedule = {
    # Scan all politicians daily at 2 AM
    'scan-all-politicians-daily': {
        'task': 'discovery.tasks.discovery_tasks.scan_all_politicians',
        'schedule': crontab(hour=settings.SCAN_ALL_POLITICIANS_HOUR, minute=0),
        'options': {
            'queue': 'discovery',
            'time_limit': 14400,  # 4 hours
        }
    },

    # Network analysis every 6 hours
    'network-analysis-6h': {
        'task': 'discovery.tasks.discovery_tasks.continuous_network_analysis',
        'schedule': crontab(minute=0, hour=f'*/{settings.NETWORK_ANALYSIS_INTERVAL_HOURS}'),
        'options': {
            'queue': 'discovery',
            'time_limit': 7200,  # 2 hours
        }
    },

    # Anomaly hunting every 4 hours
    'anomaly-hunting-4h': {
        'task': 'discovery.tasks.discovery_tasks.hunt_for_anomalies',
        'schedule': crontab(minute=0, hour=f'*/{settings.ANOMALY_HUNTING_INTERVAL_HOURS}'),
        'options': {
            'queue': 'discovery',
        }
    },

    # Cross-market patterns daily at 4 AM
    'cross-market-patterns-daily': {
        'task': 'discovery.tasks.discovery_tasks.discover_cross_market_patterns',
        'schedule': crontab(hour=4, minute=0),
        'options': {
            'queue': 'discovery',
        }
    },

    # Model experiments weekly (Sunday at 3 AM)
    'model-experiments-weekly': {
        'task': 'discovery.tasks.research_tasks.run_model_experiments',
        'schedule': crontab(day_of_week='sunday', hour=3, minute=0),
        'options': {
            'queue': 'research',
            'time_limit': 43200,  # 12 hours
        }
    },
}

# Task routing
celery_app.conf.task_routes = {
    'discovery.tasks.discovery_tasks.*': {'queue': 'discovery'},
    'discovery.tasks.research_tasks.*': {'queue': 'research'},
}
