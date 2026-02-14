"""
Claude API integration for personalized outreach messaging.
Uses Claude Sonnet for high-quality, context-aware message generation.
Supports Anthropic Batch API for 50% cost savings on bulk operations.
"""

import json
import re
import time
from typing import Dict, Optional, List
from dataclasses import dataclass
import anthropic

from ..utils.config import settings
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


@dataclass
class PersonalizedMessage:
    """Generated personalized outreach message."""
    subject: str
    body: str
    personalized_intro: str
    key_talking_points: List[str]
    call_to_action: str
    metadata: Dict


class ClaudePersonalizer:
    """
    Generate personalized outreach messages using Claude API.
    """

    def __init__(self):
        """Initialize Claude API client."""
        if not settings.anthropic_api_key:
            raise ValueError("ANTHROPIC_API_KEY not configured")

        self.client = anthropic.Anthropic(api_key=settings.anthropic_api_key)
        self.model = settings.claude_model

    def generate_cold_email(
        self,
        business_name: str,
        owner_name: str,
        industry: str,
        business_details: Dict,
        tone: str = "professional",
        max_tokens: int = 1000
    ) -> PersonalizedMessage:
        """
        Generate personalized cold email for initial outreach.

        Args:
            business_name: Company name
            owner_name: Owner's name
            industry: Business industry
            business_details: Dict with additional context
            tone: Email tone (professional, friendly, consultative)
            max_tokens: Maximum response length

        Returns:
            PersonalizedMessage object
        """
        logger.info(f"Generating cold email for {business_name}")

        # Build context from business details
        context = self._build_context(business_name, owner_name, industry, business_details)

        # Construct prompt
        prompt = f"""<role>You are a business development specialist writing a personalized acquisition outreach email. You represent an individual buyer looking to acquire and personally operate a single business for the long term, NOT a private equity firm.</role>

<context>
<business>
Name: {business_name}
Owner: {owner_name}
Industry: {industry}
</business>

{context}
</context>

<tone>{tone}</tone>

<instructions>
Write a personalized cold email that:

1. Opens with a SPECIFIC observation about their business (show you've done research)
2. Establishes credibility as a serious buyer
3. Uses "stewardship" and "continuation of your legacy" language
4. Emphasizes you're an individual operator, not PE (no predetermined exit, no financial engineering)
5. Focuses on continuity: protecting employees, maintaining operations, preserving community presence
6. Keeps it concise (under 200 words)
7. Ends with a soft call-to-action (informational conversation, no pressure)

AVOID:
- Mass-produced templates
- Leading with EBITDA multiples
- PE-speak like "platform acquisition", "synergies", "optimization"
- Artificial urgency
- Generic compliments

Format your response as JSON:
{{
  "subject": "Email subject line (under 60 characters)",
  "personalized_intro": "Opening paragraph with specific observation",
  "body": "Full email body",
  "key_talking_points": ["Point 1", "Point 2", "Point 3"],
  "call_to_action": "The specific ask/next step"
}}
</instructions>"""

        try:
            # Call Claude API
            message = self.client.messages.create(
                model=self.model,
                max_tokens=max_tokens,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )

            # Parse response
            response_text = message.content[0].text

            # Extract JSON (Claude sometimes wraps in markdown code blocks)
            json_match = re.search(r'```(?:json)?\s*(\{.*?\})\s*```', response_text, re.DOTALL)
            if json_match:
                response_text = json_match.group(1)

            response_data = json.loads(response_text)

            return PersonalizedMessage(
                subject=response_data['subject'],
                body=response_data['body'],
                personalized_intro=response_data['personalized_intro'],
                key_talking_points=response_data.get('key_talking_points', []),
                call_to_action=response_data['call_to_action'],
                metadata={
                    'business_name': business_name,
                    'owner_name': owner_name,
                    'industry': industry,
                    'tone': tone,
                    'model': self.model,
                    'tokens_used': message.usage.output_tokens
                }
            )

        except Exception as e:
            log_error(logger, e, {
                'business_name': business_name,
                'owner_name': owner_name
            })
            raise

    def generate_follow_up(
        self,
        business_name: str,
        owner_name: str,
        previous_message: str,
        days_since_first_contact: int,
        touch_number: int = 2
    ) -> PersonalizedMessage:
        """
        Generate follow-up email.

        Args:
            business_name: Company name
            owner_name: Owner's name
            previous_message: Text of previous email
            days_since_first_contact: Days since first outreach
            touch_number: Which follow-up (2, 3, 4, etc.)

        Returns:
            PersonalizedMessage object
        """
        logger.info(f"Generating follow-up #{touch_number} for {business_name}")

        prompt = f"""<role>You are writing a follow-up email for a business acquisition outreach.</role>

<context>
Business: {business_name}
Owner: {owner_name}
Days since first contact: {days_since_first_contact}
Touch number: {touch_number}

Previous message:
{previous_message}
</context>

<instructions>
Write a brief, respectful follow-up that:

1. References the previous email naturally
2. Adds new value (market insight, industry trend, helpful resource)
3. Maintains the personal, consultative tone
4. Respects their time
5. Gives them an easy out ("If now's not a good time, I completely understand")
6. Keeps it short (under 150 words)

For touch #{touch_number}:
{'- First follow-up: Add value, re-emphasize interest' if touch_number == 2 else ''}
{'- Second follow-up: Acknowledge silence, offer valuable insight' if touch_number == 3 else ''}
{'- Final follow-up: Graceful exit, leave door open' if touch_number >= 4 else ''}

Format as JSON:
{{
  "subject": "Email subject",
  "body": "Full email body",
  "personalized_intro": "Opening line",
  "key_talking_points": ["Point 1", "Point 2"],
  "call_to_action": "The ask"
}}
</instructions>"""

        try:
            message = self.client.messages.create(
                model=self.model,
                max_tokens=800,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )

            response_text = message.content[0].text

            json_match = re.search(r'```(?:json)?\s*(\{.*?\})\s*```', response_text, re.DOTALL)
            if json_match:
                response_text = json_match.group(1)

            response_data = json.loads(response_text)

            return PersonalizedMessage(
                subject=response_data['subject'],
                body=response_data['body'],
                personalized_intro=response_data['personalized_intro'],
                key_talking_points=response_data.get('key_talking_points', []),
                call_to_action=response_data['call_to_action'],
                metadata={
                    'business_name': business_name,
                    'touch_number': touch_number,
                    'days_since_first_contact': days_since_first_contact,
                    'model': self.model,
                    'tokens_used': message.usage.output_tokens
                }
            )

        except Exception as e:
            log_error(logger, e, {'business_name': business_name, 'touch_number': touch_number})
            raise

    def _build_context(
        self,
        business_name: str,
        owner_name: str,
        industry: str,
        details: Dict
    ) -> str:
        """Build context XML from business details."""
        context_parts = []

        # Business tenure
        if details.get('years_in_business'):
            context_parts.append(f"<tenure>In business for {details['years_in_business']:.0f} years</tenure>")

        # Revenue/size
        if details.get('estimated_revenue'):
            revenue_m = details['estimated_revenue'] / 1_000_000
            context_parts.append(f"<size>Estimated revenue: ${revenue_m:.1f}M</size>")

        # Employees
        if details.get('current_employees'):
            context_parts.append(f"<employees>{details['current_employees']} employees</employees>")

        # Location
        if details.get('city') and details.get('state'):
            context_parts.append(f"<location>{details['city']}, {details['state']}</location>")

        # Website/online presence
        if details.get('website_url'):
            context_parts.append(f"<website>{details['website_url']}</website>")

        # Recent activity/signals
        signals = []
        if details.get('owner_age') and details['owner_age'] >= 60:
            signals.append(f"Owner is {details['owner_age']} years old")

        if details.get('bizbuysell_listing'):
            signals.append("Currently listed on BizBuySell")

        if details.get('website_outdated'):
            signals.append("Website appears outdated")

        if signals:
            context_parts.append(f"<signals>{' | '.join(signals)}</signals>")

        # Custom notes
        if details.get('notes'):
            context_parts.append(f"<notes>{details['notes']}</notes>")

        return "\n".join(context_parts)

    def _build_cold_email_prompt(self, business: Dict) -> str:
        """Build the cold email prompt for a single business (reusable for batch)."""
        context = self._build_context(
            business['name'], business['owner_name'],
            business['industry'], business
        )

        return f"""<role>You are a business development specialist writing a personalized acquisition outreach email. You represent an individual buyer looking to acquire and personally operate a single business for the long term, NOT a private equity firm.</role>

<context>
<business>
Name: {business['name']}
Owner: {business['owner_name']}
Industry: {business['industry']}
</business>

{context}
</context>

<tone>professional</tone>

<instructions>
Write a personalized cold email that:

1. Opens with a SPECIFIC observation about their business (show you've done research)
2. Establishes credibility as a serious buyer
3. Uses "stewardship" and "continuation of your legacy" language
4. Emphasizes you're an individual operator, not PE (no predetermined exit, no financial engineering)
5. Focuses on continuity: protecting employees, maintaining operations, preserving community presence
6. Keeps it concise (under 200 words)
7. Ends with a soft call-to-action (informational conversation, no pressure)

AVOID:
- Mass-produced templates
- Leading with EBITDA multiples
- PE-speak like "platform acquisition", "synergies", "optimization"
- Artificial urgency
- Generic compliments

Format your response as JSON:
{{
  "subject": "Email subject line (under 60 characters)",
  "personalized_intro": "Opening paragraph with specific observation",
  "body": "Full email body",
  "key_talking_points": ["Point 1", "Point 2", "Point 3"],
  "call_to_action": "The specific ask/next step"
}}
</instructions>"""

    def batch_generate(
        self,
        businesses: List[Dict],
        use_batch_api: bool = True,
        poll_interval: int = 60,
        max_wait: int = 86400,
    ) -> List[PersonalizedMessage]:
        """
        Generate messages for multiple businesses.

        Uses the Anthropic Message Batches API for 50% cost savings when
        use_batch_api=True and claude_use_batch is enabled. Batch requests
        are processed within 24 hours.

        Args:
            businesses: List of business dicts with 'name', 'owner_name', 'industry'
            use_batch_api: Use Claude Batch API for 50% cost savings
            poll_interval: Seconds between batch status polls (default 60)
            max_wait: Maximum seconds to wait for batch (default 86400 = 24h)

        Returns:
            List of PersonalizedMessage objects
        """
        logger.info(f"Generating {len(businesses)} personalized messages")

        if use_batch_api and settings.claude_use_batch and len(businesses) >= 3:
            try:
                return self._batch_generate_via_api(businesses, poll_interval, max_wait)
            except Exception as e:
                log_error(logger, e, {'batch_size': len(businesses)})
                logger.warning("Batch API failed, falling back to sequential processing")

        # Sequential fallback
        messages = []
        for business in businesses:
            try:
                msg = self.generate_cold_email(
                    business_name=business['name'],
                    owner_name=business['owner_name'],
                    industry=business['industry'],
                    business_details=business
                )
                messages.append(msg)
            except Exception as e:
                log_error(logger, e, {'business': business['name']})
                continue

        logger.info(f"Successfully generated {len(messages)}/{len(businesses)} messages")
        return messages

    def _batch_generate_via_api(
        self,
        businesses: List[Dict],
        poll_interval: int,
        max_wait: int,
    ) -> List[PersonalizedMessage]:
        """
        Use Anthropic Message Batches API for bulk generation.

        Creates a batch of message requests, polls until completion,
        then parses all results.
        """
        logger.info(f"Using Claude Batch API for {len(businesses)} messages (50% cost savings)")

        # Build batch requests
        requests = []
        for i, business in enumerate(businesses):
            prompt = self._build_cold_email_prompt(business)
            requests.append({
                "custom_id": f"biz_{i}_{business['name'][:30].replace(' ', '_')}",
                "params": {
                    "model": self.model,
                    "max_tokens": 1000,
                    "messages": [{"role": "user", "content": prompt}],
                },
            })

        # Create the batch
        batch = self.client.messages.batches.create(requests=requests)
        batch_id = batch.id
        logger.info(f"Batch created: {batch_id} ({len(requests)} requests)")

        # Poll for completion
        elapsed = 0
        while elapsed < max_wait:
            batch_status = self.client.messages.batches.retrieve(batch_id)

            if batch_status.processing_status == "ended":
                logger.info(f"Batch {batch_id} completed")
                break

            logger.debug(
                f"Batch {batch_id} status: {batch_status.processing_status} "
                f"(elapsed: {elapsed}s)"
            )
            time.sleep(poll_interval)
            elapsed += poll_interval
        else:
            logger.warning(f"Batch {batch_id} timed out after {max_wait}s")
            raise TimeoutError(f"Batch {batch_id} did not complete within {max_wait}s")

        # Collect results
        messages = []
        results_iter = self.client.messages.batches.results(batch_id)

        # Build a lookup from custom_id to business data
        id_to_business = {}
        for i, business in enumerate(businesses):
            custom_id = f"biz_{i}_{business['name'][:30].replace(' ', '_')}"
            id_to_business[custom_id] = business

        for result in results_iter:
            custom_id = result.custom_id
            business = id_to_business.get(custom_id, {})

            if result.result.type == "succeeded":
                try:
                    response_text = result.result.message.content[0].text

                    # Parse JSON (handle markdown code blocks)
                    json_match = re.search(
                        r'```(?:json)?\s*(\{.*?\})\s*```',
                        response_text, re.DOTALL
                    )
                    if json_match:
                        response_text = json_match.group(1)

                    data = json.loads(response_text)

                    messages.append(PersonalizedMessage(
                        subject=data['subject'],
                        body=data['body'],
                        personalized_intro=data['personalized_intro'],
                        key_talking_points=data.get('key_talking_points', []),
                        call_to_action=data['call_to_action'],
                        metadata={
                            'business_name': business.get('name', ''),
                            'owner_name': business.get('owner_name', ''),
                            'industry': business.get('industry', ''),
                            'model': self.model,
                            'batch_id': batch_id,
                            'custom_id': custom_id,
                            'tokens_used': result.result.message.usage.output_tokens,
                        }
                    ))
                except Exception as e:
                    log_error(logger, e, {
                        'custom_id': custom_id,
                        'business': business.get('name', 'unknown'),
                    })
            else:
                logger.warning(
                    f"Batch item {custom_id} failed: {result.result.type} - "
                    f"{getattr(result.result, 'error', 'unknown error')}"
                )

        logger.info(
            f"Batch {batch_id}: {len(messages)}/{len(businesses)} messages generated"
        )
        return messages


# Example usage
if __name__ == "__main__":
    personalizer = ClaudePersonalizer()

    business_details = {
        'years_in_business': 18,
        'estimated_revenue': 2_500_000,
        'current_employees': 15,
        'city': 'Austin',
        'state': 'TX',
        'website_url': 'https://example-hvac.com',
        'owner_age': 67,
        'notes': 'Family-owned, excellent reputation in local community'
    }

    message = personalizer.generate_cold_email(
        business_name="Smith HVAC Services",
        owner_name="John Smith",
        industry="HVAC",
        business_details=business_details
    )

    print(f"Subject: {message.subject}\n")
    print(message.body)
    print(f"\nTokens used: {message.metadata['tokens_used']}")
