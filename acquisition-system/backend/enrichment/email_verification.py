"""
Email verification using ZeroBounce and NeverBounce.
Critical for keeping bounce rate under 2% and protecting sender reputation.
"""

from typing import Dict, Optional, List
from datetime import datetime
from dataclasses import dataclass

from ..scrapers.base import APIScraper
from ..utils.config import settings
from ..utils.database import get_db
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


@dataclass
class VerificationResult:
    """Email verification result."""
    email: str
    is_valid: bool
    status: str  # valid, invalid, catch-all, unknown, spamtrap, abuse, do_not_mail
    sub_status: Optional[str] = None  # More granular status
    free_email: bool = False  # gmail, yahoo, etc.
    disposable: bool = False
    did_you_mean: Optional[str] = None  # Suggested correction
    mx_found: bool = False
    smtp_provider: Optional[str] = None
    provider: str = ""  # Which verification service was used
    raw_response: Dict = None


class EmailVerifier:
    """
    Email verification using ZeroBounce (primary) and NeverBounce (fallback).

    Keeps bounce rate under 2% by pre-verifying all emails before sending.
    """

    def __init__(self):
        self.zerobounce = None
        self.neverbounce = None

        if settings.zerobounce_api_key:
            self.zerobounce = APIScraper(
                api_key=settings.zerobounce_api_key,
                base_url="https://api.zerobounce.net/v2",
                rate_limit=0.2  # 5 req/sec
            )
            # ZeroBounce uses API key as query param, not header
            self.zerobounce.session.headers.pop('Authorization', None)
            logger.info("Initialized ZeroBounce email verification")

        if settings.neverbounce_api_key:
            self.neverbounce = APIScraper(
                api_key=settings.neverbounce_api_key,
                base_url="https://api.neverbounce.com/v4",
                rate_limit=0.2
            )
            self.neverbounce.session.headers.pop('Authorization', None)
            logger.info("Initialized NeverBounce email verification")

        if not self.zerobounce and not self.neverbounce:
            logger.warning("No email verification provider configured")

    def verify(self, email: str) -> VerificationResult:
        """
        Verify a single email address.

        Args:
            email: Email address to verify

        Returns:
            VerificationResult with validity status
        """
        # Try ZeroBounce first
        if self.zerobounce:
            result = self._verify_zerobounce(email)
            if result:
                return result

        # Fallback to NeverBounce
        if self.neverbounce:
            result = self._verify_neverbounce(email)
            if result:
                return result

        # No provider available
        return VerificationResult(
            email=email,
            is_valid=False,
            status='unknown',
            provider='none'
        )

    def verify_batch(self, emails: List[str]) -> List[VerificationResult]:
        """
        Verify a batch of email addresses.

        Args:
            emails: List of email addresses

        Returns:
            List of VerificationResult objects
        """
        logger.info(f"Verifying batch of {len(emails)} emails")
        results = []

        for email in emails:
            try:
                result = self.verify(email)
                results.append(result)
            except Exception as e:
                log_error(logger, e, {'email': email})
                results.append(VerificationResult(
                    email=email,
                    is_valid=False,
                    status='error',
                    provider='error'
                ))

        valid_count = sum(1 for r in results if r.is_valid)
        logger.info(f"Verification complete: {valid_count}/{len(emails)} valid ({valid_count/max(len(emails),1)*100:.1f}%)")

        return results

    def _verify_zerobounce(self, email: str) -> Optional[VerificationResult]:
        """Verify using ZeroBounce API."""
        try:
            response = self.zerobounce.session.get(
                "https://api.zerobounce.net/v2/validate",
                params={
                    'api_key': settings.zerobounce_api_key,
                    'email': email,
                },
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            status = data.get('status', '').lower()

            # Map ZeroBounce statuses to our schema
            is_valid = status == 'valid'

            return VerificationResult(
                email=email,
                is_valid=is_valid,
                status=status,
                sub_status=data.get('sub_status'),
                free_email=data.get('free_email', False),
                mx_found=data.get('mx_found') == 'true',
                smtp_provider=data.get('smtp_provider'),
                did_you_mean=data.get('did_you_mean') or None,
                provider='zerobounce',
                raw_response=data,
            )

        except Exception as e:
            log_error(logger, e, {'email': email, 'provider': 'zerobounce'})
            return None

    def _verify_neverbounce(self, email: str) -> Optional[VerificationResult]:
        """Verify using NeverBounce API."""
        try:
            response = self.neverbounce.session.get(
                "https://api.neverbounce.com/v4/single/check",
                params={
                    'key': settings.neverbounce_api_key,
                    'email': email,
                },
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            # NeverBounce result codes: 0=valid, 1=invalid, 2=disposable, 3=catchall, 4=unknown
            result_code = data.get('result', 4)

            status_map = {
                0: ('valid', True),
                1: ('invalid', False),
                2: ('disposable', False),
                3: ('catch-all', True),  # Catch-all can still receive mail
                4: ('unknown', False),
            }

            status, is_valid = status_map.get(result_code, ('unknown', False))

            return VerificationResult(
                email=email,
                is_valid=is_valid,
                status=status,
                disposable=(result_code == 2),
                provider='neverbounce',
                raw_response=data,
            )

        except Exception as e:
            log_error(logger, e, {'email': email, 'provider': 'neverbounce'})
            return None

    def update_database(self, results: List[VerificationResult]):
        """
        Update contact email verification status in database.

        Args:
            results: List of verification results
        """
        with get_db() as db:
            from sqlalchemy import text

            for result in results:
                db.execute(text("""
                    UPDATE contacts
                    SET email_verified = :verified,
                        email_verified_at = :verified_at,
                        updated_at = NOW()
                    WHERE email = :email
                """), {
                    'verified': result.is_valid,
                    'verified_at': datetime.now() if result.is_valid else None,
                    'email': result.email,
                })

            logger.info(f"Updated verification status for {len(results)} contacts")

    def get_credits_remaining(self) -> Dict[str, int]:
        """Check remaining API credits."""
        credits = {}

        if self.zerobounce:
            try:
                response = self.zerobounce.session.get(
                    "https://api.zerobounce.net/v2/getcredits",
                    params={'api_key': settings.zerobounce_api_key},
                    timeout=10
                )
                data = response.json()
                credits['zerobounce'] = int(data.get('Credits', 0))
            except Exception:
                credits['zerobounce'] = -1

        if self.neverbounce:
            try:
                response = self.neverbounce.session.get(
                    "https://api.neverbounce.com/v4/account/info",
                    params={'key': settings.neverbounce_api_key},
                    timeout=10
                )
                data = response.json()
                credits['neverbounce'] = int(data.get('credits_info', {}).get('free_credits_remaining', 0))
            except Exception:
                credits['neverbounce'] = -1

        return credits


# Example usage
if __name__ == "__main__":
    verifier = EmailVerifier()

    # Single verification
    result = verifier.verify("test@example.com")
    print(f"Email: {result.email}")
    print(f"Valid: {result.is_valid}")
    print(f"Status: {result.status}")
    print(f"Provider: {result.provider}")

    # Batch verification
    emails = [
        "valid@company.com",
        "invalid@nonexistent-domain-12345.com",
        "test@gmail.com",
    ]

    results = verifier.verify_batch(emails)
    for r in results:
        print(f"  {r.email}: {'✓' if r.is_valid else '✗'} ({r.status})")

    # Check credits
    credits = verifier.get_credits_remaining()
    print(f"\nCredits remaining: {credits}")
