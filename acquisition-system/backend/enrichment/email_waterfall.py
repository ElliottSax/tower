"""
Email enrichment waterfall.
Tries multiple providers in sequence until email is found.
"""

from typing import Optional, Dict, List, Tuple
from dataclasses import dataclass
import time

from ..scrapers.base import APIScraper
from ..utils.config import settings
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


@dataclass
class EmailResult:
    """Result of email enrichment."""
    email: Optional[str]
    confidence: float  # 0.0 to 1.0
    source: str
    verified: bool = False
    additional_data: Dict = None


class EmailEnrichmentWaterfall:
    """
    Waterfall email enrichment using multiple providers.
    Tries each provider in sequence until email is found.
    """

    def __init__(self):
        self.providers = self._initialize_providers()
        self.stats = {provider: {'calls': 0, 'found': 0} for provider in self.providers.keys()}

    def _initialize_providers(self) -> Dict[str, APIScraper]:
        """Initialize configured email providers."""
        providers = {}

        if settings.prospeo_api_key:
            providers['prospeo'] = APIScraper(
                api_key=settings.prospeo_api_key,
                base_url="https://api.prospeo.io/v1"
            )

        if settings.dropcontact_api_key:
            providers['dropcontact'] = APIScraper(
                api_key=settings.dropcontact_api_key,
                base_url="https://api.dropcontact.io"
            )

        if settings.datagma_api_key:
            providers['datagma'] = APIScraper(
                api_key=settings.datagma_api_key,
                base_url="https://gateway.datagma.com/api/v1"
            )

        if settings.hunter_api_key:
            providers['hunter'] = APIScraper(
                api_key=settings.hunter_api_key,
                base_url="https://api.hunter.io/v2"
            )

        if settings.apollo_api_key:
            providers['apollo'] = APIScraper(
                api_key=settings.apollo_api_key,
                base_url="https://api.apollo.io/v1"
            )

        logger.info(f"Initialized {len(providers)} email providers: {list(providers.keys())}")
        return providers

    def find_email(
        self,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        full_name: Optional[str] = None,
        company_name: Optional[str] = None,
        domain: Optional[str] = None,
        linkedin_url: Optional[str] = None
    ) -> Optional[EmailResult]:
        """
        Find email using waterfall approach.

        Args:
            first_name: First name
            last_name: Last name
            full_name: Full name (if first/last not available)
            company_name: Company name
            domain: Company domain
            linkedin_url: LinkedIn profile URL

        Returns:
            EmailResult if found, None otherwise
        """
        if not self.providers:
            logger.warning("No email providers configured")
            return None

        # Parse full_name if provided
        if full_name and not (first_name and last_name):
            parts = full_name.split()
            if len(parts) >= 2:
                first_name = parts[0]
                last_name = parts[-1]

        logger.info(f"Finding email for: {first_name} {last_name} at {company_name or domain}")

        # Try each provider in sequence
        for provider_name, provider in self.providers.items():
            try:
                logger.debug(f"Trying provider: {provider_name}")
                self.stats[provider_name]['calls'] += 1

                result = self._query_provider(
                    provider_name,
                    provider,
                    first_name,
                    last_name,
                    company_name,
                    domain,
                    linkedin_url
                )

                if result and result.email:
                    self.stats[provider_name]['found'] += 1
                    logger.info(f"Email found via {provider_name}: {result.email}")
                    return result

            except Exception as e:
                log_error(logger, e, {
                    'provider': provider_name,
                    'name': f"{first_name} {last_name}",
                    'company': company_name
                })
                continue

        logger.info(f"No email found after trying {len(self.providers)} providers")
        return None

    def _query_provider(
        self,
        provider_name: str,
        provider: APIScraper,
        first_name: Optional[str],
        last_name: Optional[str],
        company_name: Optional[str],
        domain: Optional[str],
        linkedin_url: Optional[str]
    ) -> Optional[EmailResult]:
        """Query specific provider for email."""

        if provider_name == 'prospeo':
            return self._query_prospeo(provider, first_name, last_name, domain)

        elif provider_name == 'dropcontact':
            return self._query_dropcontact(provider, first_name, last_name, company_name)

        elif provider_name == 'datagma':
            return self._query_datagma(provider, linkedin_url)

        elif provider_name == 'hunter':
            return self._query_hunter(provider, first_name, last_name, domain, company_name)

        elif provider_name == 'apollo':
            return self._query_apollo(provider, first_name, last_name, domain, company_name)

        return None

    def _query_prospeo(
        self,
        provider: APIScraper,
        first_name: Optional[str],
        last_name: Optional[str],
        domain: Optional[str]
    ) -> Optional[EmailResult]:
        """Query Prospeo API."""
        if not all([first_name, last_name, domain]):
            return None

        try:
            response = provider.api_get("email-finder", params={
                'first_name': first_name,
                'last_name': last_name,
                'domain': domain
            })

            if response.get('email'):
                return EmailResult(
                    email=response['email'],
                    confidence=response.get('score', 50) / 100.0,
                    source='prospeo',
                    verified=response.get('verified', False),
                    additional_data=response
                )

        except Exception as e:
            logger.debug(f"Prospeo query failed: {e}")

        return None

    def _query_dropcontact(
        self,
        provider: APIScraper,
        first_name: Optional[str],
        last_name: Optional[str],
        company_name: Optional[str]
    ) -> Optional[EmailResult]:
        """Query DropContact API."""
        if not all([first_name, last_name, company_name]):
            return None

        try:
            response = provider.api_post("contacts", data={
                'data': [{
                    'first_name': first_name,
                    'last_name': last_name,
                    'company': company_name
                }]
            })

            if response.get('data') and len(response['data']) > 0:
                contact = response['data'][0]
                if contact.get('email'):
                    return EmailResult(
                        email=contact['email'],
                        confidence=contact.get('email_quality', 50) / 100.0,
                        source='dropcontact',
                        verified=True,
                        additional_data=contact
                    )

        except Exception as e:
            logger.debug(f"DropContact query failed: {e}")

        return None

    def _query_datagma(
        self,
        provider: APIScraper,
        linkedin_url: Optional[str]
    ) -> Optional[EmailResult]:
        """Query Datagma API (LinkedIn-based)."""
        if not linkedin_url:
            return None

        try:
            response = provider.api_post("people/linkedin", data={
                'url': linkedin_url
            })

            if response.get('email'):
                return EmailResult(
                    email=response['email'],
                    confidence=response.get('confidence', 50) / 100.0,
                    source='datagma',
                    additional_data=response
                )

        except Exception as e:
            logger.debug(f"Datagma query failed: {e}")

        return None

    def _query_hunter(
        self,
        provider: APIScraper,
        first_name: Optional[str],
        last_name: Optional[str],
        domain: Optional[str],
        company_name: Optional[str]
    ) -> Optional[EmailResult]:
        """Query Hunter.io API."""
        if not all([first_name, last_name, (domain or company_name)]):
            return None

        try:
            params = {
                'first_name': first_name,
                'last_name': last_name,
                'domain': domain
            }

            if not domain and company_name:
                # First get domain from company name
                domain_resp = provider.api_get("domain-search", params={'company': company_name})
                domain = domain_resp.get('domain')
                if domain:
                    params['domain'] = domain

            response = provider.api_get("email-finder", params=params)

            if response.get('data', {}).get('email'):
                data = response['data']
                return EmailResult(
                    email=data['email'],
                    confidence=data.get('score', 50) / 100.0,
                    source='hunter',
                    verified=data.get('verification', {}).get('status') == 'valid',
                    additional_data=data
                )

        except Exception as e:
            logger.debug(f"Hunter query failed: {e}")

        return None

    def _query_apollo(
        self,
        provider: APIScraper,
        first_name: Optional[str],
        last_name: Optional[str],
        domain: Optional[str],
        company_name: Optional[str]
    ) -> Optional[EmailResult]:
        """Query Apollo.io API."""
        if not all([first_name, last_name]):
            return None

        try:
            data = {
                'first_name': first_name,
                'last_name': last_name
            }

            if domain:
                data['domain'] = domain
            elif company_name:
                data['organization_name'] = company_name

            response = provider.api_post("people/match", data=data)

            if response.get('person', {}).get('email'):
                person = response['person']
                return EmailResult(
                    email=person['email'],
                    confidence=person.get('email_confidence', 50) / 100.0,
                    source='apollo',
                    verified=person.get('email_status') == 'verified',
                    additional_data=person
                )

        except Exception as e:
            logger.debug(f"Apollo query failed: {e}")

        return None

    def get_stats(self) -> Dict:
        """Get enrichment statistics."""
        total_calls = sum(s['calls'] for s in self.stats.values())
        total_found = sum(s['found'] for s in self.stats.values())

        return {
            'total_calls': total_calls,
            'total_found': total_found,
            'success_rate': (total_found / total_calls * 100) if total_calls > 0 else 0,
            'by_provider': self.stats
        }


# Example usage
if __name__ == "__main__":
    waterfall = EmailEnrichmentWaterfall()

    # Find email
    result = waterfall.find_email(
        first_name="John",
        last_name="Smith",
        company_name="Acme Corp",
        domain="acme.com"
    )

    if result:
        print(f"Found: {result.email} (confidence: {result.confidence:.2f}, source: {result.source})")
    else:
        print("Email not found")

    # Print stats
    print(f"\nStats: {waterfall.get_stats()}")
