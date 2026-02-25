"""
AI personalization using Groq API (completely FREE).

Groq provides free access to Llama 3.1 70B at blazing speed.
Perfect for bootstrap mode.
"""

from typing import Dict, List, Optional
import os

try:
    from groq import Groq
    GROQ_AVAILABLE = True
except ImportError:
    GROQ_AVAILABLE = False
    print("⚠️  Groq not installed. Run: pip install groq")

from ..utils.logging import setup_logging


logger = setup_logging(__name__)


class GroqPersonalizer:
    """
    Free AI personalization using Groq API.

    Benefits:
    - Completely FREE (no credit card needed)
    - Fast (30 tokens/sec on 70B model)
    - Quality: 85-90% as good as Claude

    Limits:
    - 30 requests/minute
    - 14,400 requests/day

    Cost: $0
    """

    def __init__(self):
        """Initialize Groq client."""
        if not GROQ_AVAILABLE:
            raise ImportError("Groq SDK not installed. Run: pip install groq")

        api_key = os.environ.get("GROQ_API_KEY")
        if not api_key:
            raise ValueError(
                "GROQ_API_KEY not set. Get free key at: https://console.groq.com"
            )

        self.client = Groq(api_key=api_key)
        self.model = "llama-3.1-70b-versatile"  # Best free model

    def personalize_email(
        self,
        business_name: str,
        owner_name: str,
        owner_age: Optional[int] = None,
        years_in_business: Optional[int] = None,
        industry: Optional[str] = None,
        revenue: Optional[str] = None,
        retirement_signals: Optional[List[str]] = None,
        sender_name: str = "Your Name"
    ) -> str:
        """
        Generate personalized outreach email using Groq (FREE).

        Args:
            business_name: Company name
            owner_name: Owner's name
            owner_age: Owner's age (if known)
            years_in_business: Years since incorporation
            industry: Industry/sector
            revenue: Estimated revenue
            retirement_signals: List of signals detected
            sender_name: Your name for signature

        Returns:
            Personalized email text
        """

        # Build context for AI
        context = f"Business: {business_name}\nOwner: {owner_name}"

        if owner_age:
            context += f"\nOwner age: {owner_age}"

        if years_in_business:
            context += f"\nIn business: {years_in_business} years"

        if industry:
            context += f"\nIndustry: {industry}"

        if revenue:
            context += f"\nRevenue: {revenue}"

        if retirement_signals:
            context += f"\nRetirement signals:\n- " + "\n- ".join(retirement_signals)

        # Prompt for AI
        prompt = f"""You are helping a searcher (individual buying one business) write a personalized cold email to a retiring business owner.

{context}

Write a compelling, personalized outreach email that:
1. Shows you've researched their business (reference specific details)
2. Acknowledges their legacy and accomplishments
3. Positions yourself as individual searcher (NOT a PE firm)
4. Focuses on smooth transition and preserving what they've built
5. Asks for a brief call (15 minutes)
6. Keeps it under 100 words
7. Professional but warm tone

Subject line and body. Use plain text, no HTML.
"""

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are an expert at writing personalized cold emails for business acquisition. You write concisely and authentically."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.7,
                max_tokens=400,
                top_p=0.9
            )

            email_text = response.choices[0].message.content.strip()

            # Add signature if not already included
            if sender_name not in email_text:
                email_text += f"\n\nBest,\n{sender_name}"

            logger.info(f"Generated personalized email for {business_name} using Groq (FREE)")
            return email_text

        except Exception as e:
            logger.error(f"Groq personalization failed: {str(e)}")

            # Fallback to simple template
            return self._fallback_template(
                business_name, owner_name, years_in_business, sender_name
            )

    def _fallback_template(
        self,
        business_name: str,
        owner_name: str,
        years_in_business: Optional[int],
        sender_name: str
    ) -> str:
        """Simple template fallback if AI fails."""

        tenure_text = ""
        if years_in_business and years_in_business > 15:
            tenure_text = f" After {years_in_business} years building {business_name},"

        return f"""Subject: {business_name} transition conversation

Hi {owner_name.split()[0]},

I came across {business_name} and was impressed by what you've built.{tenure_text} I imagine you've thought about next steps.

I'm a searcher looking to acquire and operate one business—not a PE firm doing rollups. If you're open to a conversation about the future, I'd love to connect.

Would you have 15 minutes for a brief call?

Best,
{sender_name}
"""

    def generate_batch(
        self,
        leads: List[Dict],
        sender_name: str = "Your Name"
    ) -> List[Dict]:
        """
        Generate personalized emails for a batch of leads.

        Args:
            leads: List of lead dicts with business info
            sender_name: Your name for signatures

        Returns:
            List of dicts with added 'personalized_email' field
        """

        results = []

        for i, lead in enumerate(leads):
            # Rate limiting: Groq allows 30/min
            # Add small delay every 30 requests
            if i > 0 and i % 30 == 0:
                logger.info("Rate limit: Sleeping 60s...")
                import time
                time.sleep(60)

            email = self.personalize_email(
                business_name=lead.get('business_name', ''),
                owner_name=lead.get('owner_name', ''),
                owner_age=lead.get('owner_age'),
                years_in_business=lead.get('years_in_business'),
                industry=lead.get('industry'),
                revenue=lead.get('revenue'),
                retirement_signals=lead.get('retirement_signals', []),
                sender_name=sender_name
            )

            lead['personalized_email'] = email
            results.append(lead)

        logger.info(f"Generated {len(results)} personalized emails via Groq (FREE)")
        return results


# Convenience function
def personalize_with_groq(business_data: Dict, sender_name: str = "Your Name") -> str:
    """Quick helper to personalize one email."""
    personalizer = GroqPersonalizer()
    return personalizer.personalize_email(
        business_name=business_data.get('business_name', ''),
        owner_name=business_data.get('owner_name', ''),
        owner_age=business_data.get('owner_age'),
        years_in_business=business_data.get('years_in_business'),
        industry=business_data.get('industry'),
        sender_name=sender_name
    )
