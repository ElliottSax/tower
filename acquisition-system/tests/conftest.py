"""Shared test fixtures for the acquisition system."""

import os
import uuid
from datetime import datetime, date, timedelta
from unittest.mock import MagicMock, patch

import pytest

# Set test env vars before importing anything that reads config
os.environ.setdefault("DATABASE_URL", "postgresql://test:test@localhost:5432/test_acquisition")
os.environ.setdefault("ANTHROPIC_API_KEY", "sk-test-fake-key-for-testing")


# --- Business Data Fixtures ---

@pytest.fixture
def sample_business_data():
    """Typical business data dict for scoring/enrichment tests."""
    return {
        'owner_age': 67,
        'incorporation_date': '2005-03-15',
        'bizbuysell_listing': False,
        'website_last_updated': '2023-01-01',
        'website_ssl_valid': True,
        'estimated_revenue': 2_500_000,
        'current_employees': 15,
        'employees_1_year_ago': 18,
        'industry': 'HVAC',
        'entity_type': 'LLC',
        'has_succession_plan': False,
        'linkedin_last_post_days': 120,
        'google_reviews_last_90_days': 3,
        'google_reviews_previous_90_days': 8,
    }


@pytest.fixture
def hot_lead_data():
    """Business data that should score as HOT (>=0.70)."""
    return {
        'owner_age': 72,
        'incorporation_date': '1998-06-01',
        'bizbuysell_listing': True,
        'website_last_updated': '2021-06-01',
        'website_ssl_valid': False,
        'estimated_revenue': 3_000_000,
        'current_employees': 12,
        'employees_1_year_ago': 18,
        'industry': 'plumbing',
        'entity_type': 'Corporation',
        'has_succession_plan': False,
        'linkedin_last_post_days': 200,
    }


@pytest.fixture
def cold_lead_data():
    """Business data that should score as COLD (<0.45)."""
    return {
        'owner_age': 35,
        'incorporation_date': '2020-01-01',
        'bizbuysell_listing': False,
        'website_last_updated': date.today().isoformat(),
        'website_ssl_valid': True,
        'estimated_revenue': 500_000,
        'current_employees': 5,
        'employees_1_year_ago': 4,
        'industry': 'IT Services',
        'entity_type': 'LLC',
        'has_succession_plan': True,
        'linkedin_last_post_days': 5,
    }


@pytest.fixture
def sample_sde_inputs():
    """Typical SDE calculation inputs."""
    return {
        'net_income': 150_000,
        'owner_salary': 120_000,
        'owner_benefits': 25_000,
        'interest': 15_000,
        'depreciation': 30_000,
        'amortization': 5_000,
        'owner_perks': {
            'Vehicle': 8_000,
            'Cell Phone': 1_200,
            'Personal Travel': 5_000,
        },
        'one_time_expenses': {
            'Lawsuit Settlement': 20_000,
        },
        'market_rate_salary': 100_000,
    }


# --- Mock Fixtures ---

@pytest.fixture
def mock_anthropic_client():
    """Mock Anthropic client for Claude API tests."""
    mock_client = MagicMock()
    mock_message = MagicMock()
    mock_message.content = [MagicMock(text='{"subject": "Test Subject", "body": "Test Body", "personalized_intro": "Test Intro", "key_talking_points": ["Point 1"], "call_to_action": "Let\'s chat"}')]
    mock_message.usage.output_tokens = 150
    mock_client.messages.create.return_value = mock_message
    return mock_client


@pytest.fixture
def mock_classifier_response():
    """Mock Claude response for classification tests."""
    return '{"sentiment": "interested", "confidence": 0.9, "summary": "Owner wants to talk", "key_concerns": [], "suggested_action": "Schedule call", "urgency": "high", "follow_up_message": "Thanks for your interest"}'


@pytest.fixture
def mock_batch_response():
    """Mock Anthropic Batch API response."""
    mock = MagicMock()
    mock.id = "batch_test_123"
    mock.processing_status = "ended"
    return mock
