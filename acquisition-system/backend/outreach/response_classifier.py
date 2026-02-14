"""
Response classifier using Claude AI.
Classifies email responses and auto-generates appropriate follow-ups.
"""

from typing import Dict, Optional, List, Tuple
from dataclasses import dataclass
from enum import Enum
import json
import re

import anthropic

from ..utils.config import settings
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


class ResponseSentiment(Enum):
    """Classification of email response sentiment."""
    INTERESTED = "interested"              # Wants to learn more, open to conversation
    NOT_INTERESTED = "not_interested"      # Clear no, don't want to sell
    NOT_NOW = "not_now"                    # Timing isn't right, but open to future
    PRICE_OBJECTION = "price_objection"    # Interested but price expectations gap
    IDENTITY_OBJECTION = "identity_objection"  # "No one can run it like me"
    INFORMATION_REQUEST = "information_request"  # Wants more details before deciding
    HOSTILE = "hostile"                    # Angry, threatening, remove from list
    AUTO_REPLY = "auto_reply"              # Out of office, auto-responder
    UNSUBSCRIBE = "unsubscribe"            # Wants to be removed
    UNCLEAR = "unclear"                    # Can't determine intent


@dataclass
class ClassificationResult:
    """Result of response classification."""
    sentiment: ResponseSentiment
    confidence: float  # 0-1
    summary: str  # Brief summary of the response
    key_concerns: List[str]  # Identified concerns or objections
    suggested_action: str  # What to do next
    follow_up_message: Optional[str]  # Auto-generated follow-up if appropriate
    urgency: str  # high, medium, low
    metadata: Dict = None


class ResponseClassifier:
    """
    Classifies email responses using Claude and generates appropriate follow-ups.

    Based on the psychological framework from the acquisition playbook:
    - "I'm not ready to sell" → Pivot to relationship-building
    - "No one can run this like me" → Validate, offer extended transition
    - Price gaps → Reframe around creative deal structures
    """

    def __init__(self):
        if not settings.anthropic_api_key:
            raise ValueError("ANTHROPIC_API_KEY not configured")

        self.client = anthropic.Anthropic(api_key=settings.anthropic_api_key)
        self.model = settings.claude_model

    def classify(
        self,
        response_text: str,
        original_message: Optional[str] = None,
        business_name: Optional[str] = None,
        owner_name: Optional[str] = None
    ) -> ClassificationResult:
        """
        Classify an email response.

        Args:
            response_text: The reply email text
            original_message: Our original outreach email
            business_name: Name of the business
            owner_name: Name of the owner who replied

        Returns:
            ClassificationResult with sentiment and recommended action
        """
        logger.info(f"Classifying response from {owner_name or 'unknown'}")

        prompt = f"""<role>You are an M&A deal sourcing specialist analyzing email responses from business owners. Classify the response and recommend the optimal next action.</role>

<context>
{f'Business: {business_name}' if business_name else ''}
{f'Owner: {owner_name}' if owner_name else ''}

{f'Our original message:{chr(10)}{original_message}' if original_message else ''}

Their response:
{response_text}
</context>

<instructions>
Classify this response into one of these categories:

1. **interested** - Wants to learn more, open to a conversation
2. **not_interested** - Clear rejection, does not want to sell
3. **not_now** - Not the right time, but open to staying in touch
4. **price_objection** - Interested but has expectations about value/price
5. **identity_objection** - Concerned no one can run the business like them
6. **information_request** - Wants more details before engaging further
7. **hostile** - Angry, aggressive, or threatening tone
8. **auto_reply** - Automated out-of-office or auto-responder
9. **unsubscribe** - Wants to be removed from communications
10. **unclear** - Cannot determine intent

Also provide:
- A confidence score (0.0 to 1.0)
- A brief summary of the response (one sentence)
- Key concerns or objections raised
- Recommended next action
- Urgency level (high/medium/low)
- A draft follow-up message IF appropriate (not for hostile/unsubscribe/auto_reply)

For follow-up messages, use these research-backed approaches:
- For "not ready to sell": Pivot to relationship building, offer value
- For "no one can run it like me": Validate concern, mention extended transition (12-24 months)
- For price objections: Reframe around creative deal structures
- For information requests: Provide requested info, maintain soft approach
- For "not now": Acknowledge timing, ask to check back, offer valuable resource

Keep follow-up messages under 150 words, warm and respectful.

Respond in JSON:
{{
    "sentiment": "one of the categories above",
    "confidence": 0.0-1.0,
    "summary": "Brief summary",
    "key_concerns": ["concern1", "concern2"],
    "suggested_action": "What to do next",
    "urgency": "high|medium|low",
    "follow_up_message": "Draft follow-up or null"
}}
</instructions>"""

        try:
            message = self.client.messages.create(
                model=self.model,
                max_tokens=800,
                messages=[{"role": "user", "content": prompt}]
            )

            response = message.content[0].text

            # Parse JSON
            json_match = re.search(r'```(?:json)?\s*(\{.*?\})\s*```', response, re.DOTALL)
            if json_match:
                response = json_match.group(1)

            data = json.loads(response)

            # Map sentiment string to enum
            try:
                sentiment = ResponseSentiment(data['sentiment'])
            except ValueError:
                sentiment = ResponseSentiment.UNCLEAR

            return ClassificationResult(
                sentiment=sentiment,
                confidence=float(data.get('confidence', 0.5)),
                summary=data.get('summary', ''),
                key_concerns=data.get('key_concerns', []),
                suggested_action=data.get('suggested_action', ''),
                follow_up_message=data.get('follow_up_message'),
                urgency=data.get('urgency', 'medium'),
                metadata={
                    'model': self.model,
                    'tokens_used': message.usage.output_tokens,
                    'business_name': business_name,
                    'owner_name': owner_name,
                }
            )

        except Exception as e:
            log_error(logger, e, {'response_text': response_text[:200]})
            return ClassificationResult(
                sentiment=ResponseSentiment.UNCLEAR,
                confidence=0.0,
                summary="Classification failed",
                key_concerns=[],
                suggested_action="Manual review required",
                follow_up_message=None,
                urgency="medium",
            )

    def classify_batch(self, responses: List[Dict]) -> List[ClassificationResult]:
        """
        Classify multiple responses.

        Args:
            responses: List of dicts with 'response_text', 'original_message',
                      'business_name', 'owner_name'

        Returns:
            List of ClassificationResult objects
        """
        results = []

        for resp in responses:
            result = self.classify(
                response_text=resp['response_text'],
                original_message=resp.get('original_message'),
                business_name=resp.get('business_name'),
                owner_name=resp.get('owner_name'),
            )
            results.append(result)

        # Summary stats
        sentiment_counts = {}
        for r in results:
            name = r.sentiment.value
            sentiment_counts[name] = sentiment_counts.get(name, 0) + 1

        logger.info(f"Classified {len(results)} responses: {sentiment_counts}")

        return results

    def should_follow_up(self, result: ClassificationResult) -> bool:
        """Determine if a follow-up should be sent."""
        # Never follow up on these
        no_follow_up = {
            ResponseSentiment.HOSTILE,
            ResponseSentiment.UNSUBSCRIBE,
            ResponseSentiment.AUTO_REPLY,
        }

        if result.sentiment in no_follow_up:
            return False

        # Always follow up on these
        yes_follow_up = {
            ResponseSentiment.INTERESTED,
            ResponseSentiment.INFORMATION_REQUEST,
            ResponseSentiment.NOT_NOW,
        }

        if result.sentiment in yes_follow_up:
            return True

        # Conditional follow-up based on confidence
        if result.sentiment == ResponseSentiment.PRICE_OBJECTION:
            return True  # Always worth engaging on price

        if result.sentiment == ResponseSentiment.IDENTITY_OBJECTION:
            return True  # Research shows this can be addressed

        if result.sentiment == ResponseSentiment.NOT_INTERESTED:
            return result.confidence < 0.8  # Follow up if we're not sure

        return False

    def get_follow_up_delay_days(self, result: ClassificationResult) -> int:
        """Get recommended delay before sending follow-up."""
        delays = {
            ResponseSentiment.INTERESTED: 0,  # Same day
            ResponseSentiment.INFORMATION_REQUEST: 0,  # Same day
            ResponseSentiment.PRICE_OBJECTION: 2,
            ResponseSentiment.IDENTITY_OBJECTION: 3,
            ResponseSentiment.NOT_NOW: 14,  # 2 weeks
            ResponseSentiment.NOT_INTERESTED: 30,  # 1 month (gentle)
            ResponseSentiment.UNCLEAR: 3,
        }

        return delays.get(result.sentiment, 7)


# Example usage
if __name__ == "__main__":
    classifier = ResponseClassifier()

    # Test responses
    test_responses = [
        {
            'response_text': "Thanks for reaching out. I've actually been thinking about retirement. Would love to chat more about this. How about next Tuesday?",
            'business_name': 'Smith HVAC',
            'owner_name': 'John Smith',
        },
        {
            'response_text': "I appreciate the email but I'm not looking to sell right now. The business is doing great and I plan to keep running it.",
            'business_name': 'Johnson Plumbing',
            'owner_name': 'Bob Johnson',
        },
        {
            'response_text': "I've had other offers before. My business is worth at least $3M. If you're serious, come with a real number.",
            'business_name': 'Williams Electric',
            'owner_name': 'Tom Williams',
        },
        {
            'response_text': "I'm out of the office until January 15th. I'll respond when I return.",
            'business_name': None,
            'owner_name': None,
        },
    ]

    for resp in test_responses:
        result = classifier.classify(**resp)
        print(f"\nBusiness: {resp.get('business_name', 'Unknown')}")
        print(f"Sentiment: {result.sentiment.value} (confidence: {result.confidence:.2f})")
        print(f"Summary: {result.summary}")
        print(f"Urgency: {result.urgency}")
        print(f"Action: {result.suggested_action}")
        print(f"Follow up: {'Yes' if classifier.should_follow_up(result) else 'No'}")
        if result.follow_up_message:
            print(f"Draft:\n{result.follow_up_message}")
