"""
Secretary of State business registry scraper.
Supports multiple states via APIs and web scraping.
"""

from typing import List, Dict, Optional
from datetime import datetime, date
from dataclasses import dataclass, asdict

from .base import APIScraper, BaseScraper
from ..utils.config import settings
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


@dataclass
class BusinessRecord:
    """Standardized business record from SoS."""
    name: str
    entity_number: str
    entity_type: str
    incorporation_date: Optional[date]
    status: str
    state: str

    # Location
    street_address: Optional[str] = None
    city: Optional[str] = None
    zip_code: Optional[str] = None

    # Officers/agents
    officers: List[Dict] = None

    # Metadata
    source: str = "sos"
    scraped_at: datetime = None
    raw_data: Dict = None

    def __post_init__(self):
        if self.officers is None:
            self.officers = []
        if self.scraped_at is None:
            self.scraped_at = datetime.now()

    def to_dict(self) -> Dict:
        """Convert to dictionary for database insertion."""
        data = asdict(self)
        if isinstance(data['incorporation_date'], date):
            data['incorporation_date'] = data['incorporation_date'].isoformat()
        if isinstance(data['scraped_at'], datetime):
            data['scraped_at'] = data['scraped_at'].isoformat()
        return data


class CaliforniaSoSScraper(APIScraper):
    """California Secretary of State API scraper."""

    def __init__(self):
        if not settings.ca_sos_api_key:
            raise ValueError("CA_SOS_API_KEY not configured")

        super().__init__(
            api_key=settings.ca_sos_api_key,
            base_url="https://api.sos.ca.gov/v1"
        )

    def scrape(self, entity_number: Optional[str] = None, name: Optional[str] = None) -> List[BusinessRecord]:
        """
        Scrape California business records.

        Args:
            entity_number: Specific entity number to fetch
            name: Search by business name

        Returns:
            List of BusinessRecord objects
        """
        if entity_number:
            return [self._fetch_entity(entity_number)]
        elif name:
            return self._search_by_name(name)
        else:
            raise ValueError("Must provide either entity_number or name")

    def _fetch_entity(self, entity_number: str) -> BusinessRecord:
        """Fetch specific entity by number."""
        try:
            data = self.api_get(f"business-entities/{entity_number}")
            return self._parse_entity(data)

        except Exception as e:
            log_error(logger, e, {'entity_number': entity_number})
            raise

    def _search_by_name(self, name: str) -> List[BusinessRecord]:
        """Search for entities by name."""
        try:
            data = self.api_get("business-entities/search", params={'name': name})
            return [self._parse_entity(entity) for entity in data.get('results', [])]

        except Exception as e:
            log_error(logger, e, {'search_name': name})
            return []

    def _parse_entity(self, data: Dict) -> BusinessRecord:
        """Parse API response into BusinessRecord."""
        # Parse incorporation date
        inc_date = None
        if data.get('incorporationDate'):
            try:
                inc_date = datetime.fromisoformat(data['incorporationDate']).date()
            except (ValueError, TypeError):
                pass

        # Extract officers
        officers = []
        for officer in data.get('officers', []):
            officers.append({
                'full_name': officer.get('name'),
                'title': officer.get('title'),
                'role_type': self._classify_role(officer.get('title', '')),
                'address': officer.get('address')
            })

        return BusinessRecord(
            name=data.get('entityName', ''),
            entity_number=data.get('entityNumber', ''),
            entity_type=data.get('entityType', ''),
            incorporation_date=inc_date,
            status=data.get('status', '').lower(),
            state='CA',
            street_address=data.get('principalAddress', {}).get('street'),
            city=data.get('principalAddress', {}).get('city'),
            zip_code=data.get('principalAddress', {}).get('zipCode'),
            officers=officers,
            raw_data=data
        )

    @staticmethod
    def _classify_role(title: str) -> str:
        """Classify officer role from title."""
        title_lower = title.lower()

        if any(word in title_lower for word in ['owner', 'member', 'partner']):
            return 'owner'
        elif any(word in title_lower for word in ['ceo', 'president', 'cfo', 'coo', 'officer']):
            return 'officer'
        elif 'agent' in title_lower:
            return 'agent'
        elif any(word in title_lower for word in ['director', 'board']):
            return 'director'
        else:
            return 'other'


class MultiStateSoSScraper:
    """
    Unified interface for scraping multiple states.
    Uses aggregation services like Cobalt or Middesk for comprehensive coverage.
    """

    def __init__(self):
        self.scrapers = {}

        # Initialize state-specific scrapers
        if settings.ca_sos_api_key:
            self.scrapers['CA'] = CaliforniaSoSScraper()

        # Use aggregation service if configured
        if settings.cobalt_api_key:
            self.aggregator = APIScraper(
                api_key=settings.cobalt_api_key,
                base_url="https://api.cobaltintelligence.com/v1"
            )
        elif settings.middesk_api_key:
            self.aggregator = APIScraper(
                api_key=settings.middesk_api_key,
                base_url="https://api.middesk.com/v1"
            )
        else:
            self.aggregator = None
            logger.warning("No aggregation service configured. Limited to state-specific APIs.")

    def scrape_state(self, state: str, **kwargs) -> List[BusinessRecord]:
        """
        Scrape businesses from a specific state.

        Args:
            state: Two-letter state code
            **kwargs: Additional search parameters

        Returns:
            List of BusinessRecord objects
        """
        # Try state-specific scraper first
        if state in self.scrapers:
            logger.info(f"Using state-specific scraper for {state}")
            return self.scrapers[state].scrape(**kwargs)

        # Fall back to aggregation service
        if self.aggregator:
            logger.info(f"Using aggregation service for {state}")
            return self._scrape_via_aggregator(state, **kwargs)

        logger.error(f"No scraper available for state: {state}")
        return []

    def _scrape_via_aggregator(self, state: str, **kwargs) -> List[BusinessRecord]:
        """Scrape via aggregation service (Cobalt/Middesk)."""
        try:
            # This is a generic implementation - adjust based on actual API
            params = {'state': state, **kwargs}
            data = self.aggregator.api_get("business-entities", params=params)

            records = []
            for entity in data.get('results', []):
                records.append(BusinessRecord(
                    name=entity.get('name', ''),
                    entity_number=entity.get('entity_number', ''),
                    entity_type=entity.get('entity_type', ''),
                    incorporation_date=entity.get('incorporation_date'),
                    status=entity.get('status', '').lower(),
                    state=state,
                    street_address=entity.get('address', {}).get('street'),
                    city=entity.get('address', {}).get('city'),
                    zip_code=entity.get('address', {}).get('zip_code'),
                    officers=entity.get('officers', []),
                    raw_data=entity
                ))

            return records

        except Exception as e:
            log_error(logger, e, {'state': state, 'kwargs': kwargs})
            return []

    def bulk_scrape(self, states: List[str], limit_per_state: Optional[int] = None) -> List[BusinessRecord]:
        """
        Scrape multiple states in bulk.

        Args:
            states: List of state codes
            limit_per_state: Optional limit on records per state

        Returns:
            Combined list of BusinessRecord objects
        """
        all_records = []

        for state in states:
            logger.info(f"Scraping state: {state}")

            try:
                records = self.scrape_state(state)

                if limit_per_state:
                    records = records[:limit_per_state]

                all_records.extend(records)
                logger.info(f"Found {len(records)} businesses in {state}")

            except Exception as e:
                log_error(logger, e, {'state': state})
                continue

        logger.info(f"Total businesses scraped: {len(all_records)}")
        return all_records


# Example usage
if __name__ == "__main__":
    # Scrape California
    scraper = MultiStateSoSScraper()

    # Search by name
    results = scraper.scrape_state('CA', name='Tech Company')
    for business in results:
        print(f"{business.name} ({business.entity_number})")

    # Bulk scrape multiple states
    all_businesses = scraper.bulk_scrape(['CA', 'TX', 'NY'], limit_per_state=100)
    print(f"Total scraped: {len(all_businesses)}")
