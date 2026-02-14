"""Tests for email enrichment waterfall."""

import pytest
from unittest.mock import MagicMock, patch

from backend.enrichment.email_waterfall import (
    EmailEnrichmentWaterfall, EmailResult,
)


class TestEmailResult:
    """Test EmailResult dataclass."""

    def test_basic_result(self):
        result = EmailResult(
            email="john@acme.com",
            confidence=0.95,
            source="prospeo",
            verified=True,
        )
        assert result.email == "john@acme.com"
        assert result.confidence == 0.95
        assert result.source == "prospeo"


class TestWaterfallInitialization:
    """Test waterfall provider initialization."""

    @patch('backend.enrichment.email_waterfall.settings')
    def test_no_providers_configured(self, mock_settings):
        mock_settings.prospeo_api_key = None
        mock_settings.dropcontact_api_key = None
        mock_settings.datagma_api_key = None
        mock_settings.hunter_api_key = None
        mock_settings.apollo_api_key = None

        waterfall = EmailEnrichmentWaterfall()
        assert len(waterfall.providers) == 0

    @patch('backend.enrichment.email_waterfall.settings')
    @patch('backend.enrichment.email_waterfall.APIScraper')
    def test_single_provider(self, mock_scraper, mock_settings):
        mock_settings.prospeo_api_key = "test-key"
        mock_settings.dropcontact_api_key = None
        mock_settings.datagma_api_key = None
        mock_settings.hunter_api_key = None
        mock_settings.apollo_api_key = None

        waterfall = EmailEnrichmentWaterfall()
        assert len(waterfall.providers) == 1
        assert 'prospeo' in waterfall.providers

    @patch('backend.enrichment.email_waterfall.settings')
    @patch('backend.enrichment.email_waterfall.APIScraper')
    def test_multiple_providers(self, mock_scraper, mock_settings):
        mock_settings.prospeo_api_key = "key1"
        mock_settings.dropcontact_api_key = "key2"
        mock_settings.datagma_api_key = None
        mock_settings.hunter_api_key = "key3"
        mock_settings.apollo_api_key = None

        waterfall = EmailEnrichmentWaterfall()
        assert len(waterfall.providers) == 3


class TestWaterfallLogic:
    """Test waterfall email finding logic."""

    @patch('backend.enrichment.email_waterfall.settings')
    def test_no_providers_returns_none(self, mock_settings):
        mock_settings.prospeo_api_key = None
        mock_settings.dropcontact_api_key = None
        mock_settings.datagma_api_key = None
        mock_settings.hunter_api_key = None
        mock_settings.apollo_api_key = None

        waterfall = EmailEnrichmentWaterfall()
        result = waterfall.find_email(first_name="John", last_name="Smith")
        assert result is None

    @patch('backend.enrichment.email_waterfall.settings')
    @patch('backend.enrichment.email_waterfall.APIScraper')
    def test_first_provider_success(self, mock_scraper_cls, mock_settings):
        mock_settings.prospeo_api_key = "key"
        mock_settings.dropcontact_api_key = None
        mock_settings.datagma_api_key = None
        mock_settings.hunter_api_key = None
        mock_settings.apollo_api_key = None

        mock_scraper = MagicMock()
        mock_scraper.api_get.return_value = {
            'email': 'john@acme.com',
            'score': 95,
            'verified': True,
        }
        mock_scraper_cls.return_value = mock_scraper

        waterfall = EmailEnrichmentWaterfall()
        result = waterfall.find_email(
            first_name="John",
            last_name="Smith",
            domain="acme.com",
        )

        assert result is not None
        assert result.email == "john@acme.com"
        assert result.source == "prospeo"

    def test_full_name_parsing(self):
        """Test that full_name is split into first/last."""
        with patch('backend.enrichment.email_waterfall.settings') as mock_settings:
            mock_settings.prospeo_api_key = None
            mock_settings.dropcontact_api_key = None
            mock_settings.datagma_api_key = None
            mock_settings.hunter_api_key = None
            mock_settings.apollo_api_key = None

            waterfall = EmailEnrichmentWaterfall()
            # Even with no providers, the name parsing happens
            result = waterfall.find_email(full_name="John Smith", domain="acme.com")
            assert result is None  # No providers, but shouldn't crash


class TestWaterfallStats:
    """Test stats tracking."""

    @patch('backend.enrichment.email_waterfall.settings')
    def test_initial_stats(self, mock_settings):
        mock_settings.prospeo_api_key = None
        mock_settings.dropcontact_api_key = None
        mock_settings.datagma_api_key = None
        mock_settings.hunter_api_key = None
        mock_settings.apollo_api_key = None

        waterfall = EmailEnrichmentWaterfall()
        stats = waterfall.get_stats()

        assert stats['total_calls'] == 0
        assert stats['total_found'] == 0
        assert stats['success_rate'] == 0
