"""Outreach and personalization modules."""

from .claude_personalization import ClaudePersonalizer, PersonalizedMessage
from .email_automation import get_email_automation, InstantlyAutomation, SmartleadAutomation
from .response_classifier import ResponseClassifier, ResponseSentiment, ClassificationResult

__all__ = [
    'ClaudePersonalizer', 'PersonalizedMessage',
    'get_email_automation', 'InstantlyAutomation', 'SmartleadAutomation',
    'ResponseClassifier', 'ResponseSentiment', 'ClassificationResult',
]
