"""Tests for response classifier."""

import pytest
from unittest.mock import MagicMock, patch

from backend.outreach.response_classifier import (
    ResponseClassifier, ResponseSentiment, ClassificationResult,
)


class TestResponseSentiment:
    """Test sentiment enum."""

    def test_all_sentiments_exist(self):
        expected = [
            'interested', 'not_interested', 'not_now', 'price_objection',
            'identity_objection', 'information_request', 'hostile',
            'auto_reply', 'unsubscribe', 'unclear',
        ]
        for s in expected:
            assert ResponseSentiment(s) is not None

    def test_sentiment_values(self):
        assert ResponseSentiment.INTERESTED.value == "interested"
        assert ResponseSentiment.HOSTILE.value == "hostile"


class TestFollowUpDecisions:
    """Test follow-up decision logic (doesn't require API)."""

    def setup_method(self):
        with patch('backend.outreach.response_classifier.settings') as mock_settings:
            mock_settings.anthropic_api_key = "sk-test"
            mock_settings.claude_model = "claude-sonnet-4-5-20250929"
            with patch('backend.outreach.response_classifier.anthropic'):
                self.classifier = ResponseClassifier()

    def _make_result(self, sentiment, confidence=0.9):
        return ClassificationResult(
            sentiment=sentiment,
            confidence=confidence,
            summary="Test",
            key_concerns=[],
            suggested_action="Test action",
            follow_up_message=None,
            urgency="medium",
        )

    def test_follow_up_interested(self):
        result = self._make_result(ResponseSentiment.INTERESTED)
        assert self.classifier.should_follow_up(result) is True

    def test_follow_up_not_now(self):
        result = self._make_result(ResponseSentiment.NOT_NOW)
        assert self.classifier.should_follow_up(result) is True

    def test_follow_up_information_request(self):
        result = self._make_result(ResponseSentiment.INFORMATION_REQUEST)
        assert self.classifier.should_follow_up(result) is True

    def test_follow_up_price_objection(self):
        result = self._make_result(ResponseSentiment.PRICE_OBJECTION)
        assert self.classifier.should_follow_up(result) is True

    def test_follow_up_identity_objection(self):
        result = self._make_result(ResponseSentiment.IDENTITY_OBJECTION)
        assert self.classifier.should_follow_up(result) is True

    def test_no_follow_up_hostile(self):
        result = self._make_result(ResponseSentiment.HOSTILE)
        assert self.classifier.should_follow_up(result) is False

    def test_no_follow_up_unsubscribe(self):
        result = self._make_result(ResponseSentiment.UNSUBSCRIBE)
        assert self.classifier.should_follow_up(result) is False

    def test_no_follow_up_auto_reply(self):
        result = self._make_result(ResponseSentiment.AUTO_REPLY)
        assert self.classifier.should_follow_up(result) is False

    def test_not_interested_high_confidence_no_follow_up(self):
        result = self._make_result(ResponseSentiment.NOT_INTERESTED, confidence=0.95)
        assert self.classifier.should_follow_up(result) is False

    def test_not_interested_low_confidence_follow_up(self):
        result = self._make_result(ResponseSentiment.NOT_INTERESTED, confidence=0.6)
        assert self.classifier.should_follow_up(result) is True


class TestFollowUpDelays:
    """Test follow-up delay recommendations."""

    def setup_method(self):
        with patch('backend.outreach.response_classifier.settings') as mock_settings:
            mock_settings.anthropic_api_key = "sk-test"
            mock_settings.claude_model = "claude-sonnet-4-5-20250929"
            with patch('backend.outreach.response_classifier.anthropic'):
                self.classifier = ResponseClassifier()

    def _make_result(self, sentiment):
        return ClassificationResult(
            sentiment=sentiment,
            confidence=0.9,
            summary="Test",
            key_concerns=[],
            suggested_action="Test",
            follow_up_message=None,
            urgency="medium",
        )

    def test_interested_same_day(self):
        result = self._make_result(ResponseSentiment.INTERESTED)
        assert self.classifier.get_follow_up_delay_days(result) == 0

    def test_not_now_two_weeks(self):
        result = self._make_result(ResponseSentiment.NOT_NOW)
        assert self.classifier.get_follow_up_delay_days(result) == 14

    def test_not_interested_one_month(self):
        result = self._make_result(ResponseSentiment.NOT_INTERESTED)
        assert self.classifier.get_follow_up_delay_days(result) == 30

    def test_price_objection_two_days(self):
        result = self._make_result(ResponseSentiment.PRICE_OBJECTION)
        assert self.classifier.get_follow_up_delay_days(result) == 2
