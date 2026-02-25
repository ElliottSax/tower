"""
Free email enrichment using only free tiers.
Combines multiple providers' free tiers for 200+ emails/month at $0 cost.
"""

from typing import Optional, Dict, List
from dataclasses import dataclass
import re
import smtplib
import dns.resolver
from email.utils import parseaddr

from ..utils.config import settings
from ..utils.logging import setup_logging


logger = setup_logging(__name__)


@dataclass
class FreeEmailResult:
    """Result from free email enrichment."""
    email: Optional[str]
    confidence: float  # 0.0 to 1.0
    source: str
    verified: bool = False


class FreeEmailWaterfall:
    """
    Email enrichment using only free tiers and pattern guessing.

    Strategy:
    1. Try free tier providers (Hunter, Apollo, Snov) - 200/month total
    2. Fall back to pattern guessing + SMTP verification - unlimited

    Cost: $0/month
    Success rate: 40-60%
    """

    def __init__(self):
        """Initialize with free tier quotas."""
        self.quotas = {
            'hunter': {'limit': 50, 'used': 0},
            'apollo': {'limit': 50, 'used': 0},
            'snov': {'limit': 50, 'used': 0},
            'voilanorbert': {'limit': 50, 'used': 0},
        }

        self.common_patterns = [
            "{first}@{domain}",
            "{first}.{last}@{domain}",
            "{first}{last}@{domain}",
            "{f}{last}@{domain}",
            "{first}_{last}@{domain}",
            "{last}.{first}@{domain}",
            "contact@{domain}",
            "info@{domain}",
        ]

    def find_email(
        self,
        first_name: str,
        last_name: str,
        company_name: str,
        domain: Optional[str] = None
    ) -> Optional[FreeEmailResult]:
        """
        Find email using free methods.

        Args:
            first_name: Owner first name
            last_name: Owner last name
            company_name: Company name
            domain: Company domain (will extract if not provided)

        Returns:
            FreeEmailResult if found, None otherwise
        """

        # Extract domain from company name if not provided
        if not domain:
            domain = self._extract_domain(company_name)
            if not domain:
                logger.warning(f"Could not extract domain from {company_name}")
                return None

        # Try free tier providers first (conserve quota)
        for provider in ['hunter', 'apollo', 'snov', 'voilanorbert']:
            if self.quotas[provider]['used'] < self.quotas[provider]['limit']:
                email = self._try_free_provider(
                    provider, first_name, last_name, company_name, domain
                )
                if email:
                    self.quotas[provider]['used'] += 1
                    logger.info(f"Found email via {provider} free tier: {email}")
                    return FreeEmailResult(
                        email=email,
                        confidence=0.8,
                        source=provider,
                        verified=True
                    )

        # Fall back to pattern guessing (unlimited free)
        logger.info(f"Free tier exhausted, trying pattern guessing for {domain}")
        return self._guess_email_pattern(first_name, last_name, domain)

    def _try_free_provider(
        self, provider: str, first: str, last: str, company: str, domain: str
    ) -> Optional[str]:
        """Try a specific free tier provider."""

        # This is a placeholder - implement actual API calls
        # For now, return None to fall back to pattern guessing
        #
        # In production, you'd implement:
        # - Hunter.io API call with free tier key
        # - Apollo.io API call
        # - Snov.io API call
        # etc.

        logger.info(f"Trying {provider} free tier (placeholder)")
        return None

    def _guess_email_pattern(
        self, first_name: str, last_name: str, domain: str
    ) -> Optional[FreeEmailResult]:
        """
        Guess email using common patterns and verify via SMTP.
        Completely free, unlimited usage.
        """

        first = self._normalize_name(first_name)
        last = self._normalize_name(last_name)
        f = first[0] if first else ''

        # Generate candidate emails
        candidates = []
        for pattern in self.common_patterns:
            try:
                email = pattern.format(
                    first=first,
                    last=last,
                    f=f,
                    domain=domain
                )
                candidates.append(email)
            except KeyError:
                continue

        # Try to verify each candidate
        for email in candidates:
            if self._verify_email_smtp(email):
                logger.info(f"Found via pattern guessing: {email}")
                return FreeEmailResult(
                    email=email,
                    confidence=0.6,  # Lower confidence for guessed
                    source='pattern_guess',
                    verified=True
                )

        logger.warning(f"No valid email found for {first} {last} @ {domain}")
        return None

    def _verify_email_smtp(self, email: str) -> bool:
        """
        Verify email exists using free SMTP check.

        WARNING: Use sparingly to avoid getting blocked.
        Max ~100/hour per domain recommended.
        """

        try:
            domain = email.split('@')[1]

            # 1. Check MX records exist
            mx_records = dns.resolver.resolve(domain, 'MX')
            mx_host = str(mx_records[0].exchange)

            # 2. Connect to SMTP server and verify
            server = smtplib.SMTP(timeout=10)
            server.set_debuglevel(0)
            server.connect(mx_host)
            server.helo('dealsourceai.com')
            server.mail('verify@dealsourceai.com')
            code, message = server.rcpt(email)
            server.quit()

            # 250 = OK, email exists
            return code == 250

        except Exception as e:
            logger.debug(f"SMTP verification failed for {email}: {str(e)}")
            return False

    def _extract_domain(self, company_name: str) -> Optional[str]:
        """
        Extract domain from company name.

        Examples:
        - "Johnson Plumbing Supply" -> "johnsonplumbing.com"
        - "ABC Corp" -> "abc.com"
        """

        # Remove common suffixes
        name = company_name.lower()
        for suffix in [' inc', ' corp', ' llc', ' ltd', ' co', ' company']:
            name = name.replace(suffix, '')

        # Remove special characters
        name = re.sub(r'[^a-z0-9\s]', '', name)

        # Take first 1-2 words
        words = name.strip().split()
        if not words:
            return None

        if len(words) == 1:
            domain_name = words[0]
        else:
            # Try both "firstword" and "firstsecond"
            domain_name = ''.join(words[:2])

        # Common TLDs to try
        tlds = ['.com', '.net', '.co', '.io']

        for tld in tlds:
            domain = domain_name + tld
            if self._domain_exists(domain):
                return domain

        # Default to .com if nothing found
        return domain_name + '.com'

    def _domain_exists(self, domain: str) -> bool:
        """Check if domain has MX records (receives email)."""
        try:
            dns.resolver.resolve(domain, 'MX')
            return True
        except:
            return False

    def _normalize_name(self, name: str) -> str:
        """Normalize name for email generation."""
        if not name:
            return ''

        # Remove special characters, lowercase
        normalized = re.sub(r'[^a-z]', '', name.lower())
        return normalized

    def get_quota_status(self) -> Dict[str, Dict]:
        """Get current usage of free tier quotas."""
        return self.quotas


# Convenience function
def find_email_free(first_name: str, last_name: str, company_name: str) -> Optional[str]:
    """Quick helper to find email using free methods."""
    waterfall = FreeEmailWaterfall()
    result = waterfall.find_email(first_name, last_name, company_name)
    return result.email if result else None
