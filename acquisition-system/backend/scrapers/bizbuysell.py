"""
BizBuySell marketplace scraper for active business listings.
Strong signal of retirement/sale intent.
"""

from typing import List, Dict, Optional
from datetime import datetime
from dataclasses import dataclass, asdict
import re

from .base import PlaywrightScraper
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


@dataclass
class BusinessListing:
    """Business listing from BizBuySell."""
    title: str
    asking_price: Optional[float]
    revenue: Optional[float]
    cash_flow: Optional[float]
    industry: str
    location: str

    # Details
    description: str
    established_year: Optional[int]
    employees: Optional[int]

    # Metadata
    listing_url: str
    listing_id: str
    posted_date: Optional[datetime]
    scraped_at: datetime

    # Raw data
    raw_data: Dict = None

    def to_dict(self) -> Dict:
        """Convert to dictionary."""
        data = asdict(self)
        if isinstance(data['posted_date'], datetime):
            data['posted_date'] = data['posted_date'].isoformat()
        if isinstance(data['scraped_at'], datetime):
            data['scraped_at'] = data['scraped_at'].isoformat()
        return data


class BizBuySellScraper(PlaywrightScraper):
    """Scraper for BizBuySell.com marketplace."""

    BASE_URL = "https://www.bizbuysell.com"

    def __init__(self):
        super().__init__(headless=True)

    def scrape(
        self,
        state: Optional[str] = None,
        industry: Optional[str] = None,
        min_price: Optional[int] = None,
        max_price: Optional[int] = None,
        max_pages: int = 10
    ) -> List[BusinessListing]:
        """
        Scrape business listings with filters.

        Args:
            state: Filter by state (e.g., 'CA', 'TX')
            industry: Filter by industry
            min_price: Minimum asking price
            max_price: Maximum asking price
            max_pages: Maximum number of pages to scrape

        Returns:
            List of BusinessListing objects
        """
        logger.info(f"Scraping BizBuySell: state={state}, industry={industry}, price={min_price}-{max_price}")

        # Build search URL
        url = self._build_search_url(state, industry, min_price, max_price)

        listings = []
        page = 1

        while page <= max_pages:
            logger.info(f"Scraping page {page}/{max_pages}")

            try:
                page_url = f"{url}&page={page}" if page > 1 else url
                html = self.fetch_page(page_url)
                soup = self.parse_html(html)

                # Extract listings from page
                page_listings = self._parse_listings_page(soup)

                if not page_listings:
                    logger.info("No more listings found")
                    break

                listings.extend(page_listings)
                page += 1

            except Exception as e:
                log_error(logger, e, {'page': page, 'url': url})
                break

        logger.info(f"Scraped {len(listings)} total listings")
        return listings

    def _build_search_url(
        self,
        state: Optional[str],
        industry: Optional[str],
        min_price: Optional[int],
        max_price: Optional[int]
    ) -> str:
        """Build search URL with filters."""
        url = f"{self.BASE_URL}/businesses-for-sale/"

        params = []

        if state:
            params.append(f"q={state}")

        if industry:
            # Industry codes would need to be mapped
            params.append(f"cat={industry}")

        if min_price:
            params.append(f"priceMin={min_price}")

        if max_price:
            params.append(f"priceMax={max_price}")

        if params:
            url += "?" + "&".join(params)

        return url

    def _parse_listings_page(self, soup) -> List[BusinessListing]:
        """Parse listing cards from search results page."""
        listings = []

        # Find all listing cards (adjust selectors based on actual HTML structure)
        cards = soup.select('.listing-card, .search-result-item, article.listing')

        for card in cards:
            try:
                listing = self._parse_listing_card(card)
                if listing:
                    listings.append(listing)
            except Exception as e:
                log_error(logger, e, {'card_html': str(card)[:200]})
                continue

        return listings

    def _parse_listing_card(self, card) -> Optional[BusinessListing]:
        """Parse individual listing card."""
        try:
            # Extract basic info (adjust selectors to match actual HTML)
            title_elem = card.select_one('.listing-title, h2.title, .business-name')
            if not title_elem:
                return None

            title = title_elem.get_text(strip=True)

            # Extract price
            price_elem = card.select_one('.price, .asking-price, [class*="price"]')
            asking_price = self._parse_price(price_elem.get_text() if price_elem else None)

            # Extract revenue
            revenue_elem = card.select_one('.revenue, [class*="revenue"]')
            revenue = self._parse_price(revenue_elem.get_text() if revenue_elem else None)

            # Extract cash flow (SDE/EBITDA)
            cashflow_elem = card.select_one('.cash-flow, .ebitda, [class*="cashflow"]')
            cash_flow = self._parse_price(cashflow_elem.get_text() if cashflow_elem else None)

            # Extract industry
            industry_elem = card.select_one('.industry, .category, [class*="industry"]')
            industry = industry_elem.get_text(strip=True) if industry_elem else "Unknown"

            # Extract location
            location_elem = card.select_one('.location, .city-state, [class*="location"]')
            location = location_elem.get_text(strip=True) if location_elem else "Unknown"

            # Extract listing URL
            link_elem = card.select_one('a[href*="/business-opportunity/"]')
            if not link_elem:
                return None

            listing_url = self.BASE_URL + link_elem['href'] if link_elem['href'].startswith('/') else link_elem['href']

            # Extract listing ID from URL
            listing_id = re.search(r'/(\d+)/', listing_url)
            listing_id = listing_id.group(1) if listing_id else listing_url.split('/')[-1]

            # Get full details if needed
            description = card.select_one('.description, .summary')
            description_text = description.get_text(strip=True) if description else ""

            return BusinessListing(
                title=title,
                asking_price=asking_price,
                revenue=revenue,
                cash_flow=cash_flow,
                industry=industry,
                location=location,
                description=description_text,
                established_year=None,  # Would need detail page scrape
                employees=None,
                listing_url=listing_url,
                listing_id=listing_id,
                posted_date=None,
                scraped_at=datetime.now(),
                raw_data={'html_snippet': str(card)[:500]}
            )

        except Exception as e:
            log_error(logger, e)
            return None

    def scrape_listing_detail(self, listing_url: str) -> Dict:
        """
        Scrape detailed information from individual listing page.

        Args:
            listing_url: URL of listing detail page

        Returns:
            Dict with detailed listing information
        """
        try:
            html = self.fetch_page(listing_url)
            soup = self.parse_html(html)

            # Parse detail page (adjust selectors)
            details = {
                'description': self._get_text(soup, '.full-description, .business-description'),
                'established_year': self._get_text(soup, '.established, .year-established'),
                'employees': self._get_text(soup, '.employees, .employee-count'),
                'facilities': self._get_text(soup, '.facilities'),
                'reason_for_selling': self._get_text(soup, '.reason-selling, .motivation'),
                'training_support': self._get_text(soup, '.training, .support'),
                'financing_available': self._get_text(soup, '.financing'),
            }

            return details

        except Exception as e:
            log_error(logger, e, {'url': listing_url})
            return {}

    @staticmethod
    def _parse_price(text: Optional[str]) -> Optional[float]:
        """Parse price string to float."""
        if not text:
            return None

        # Remove $ and commas
        text = text.replace('$', '').replace(',', '').strip()

        # Handle abbreviations (K, M)
        multiplier = 1
        if text.endswith('K'):
            multiplier = 1000
            text = text[:-1]
        elif text.endswith('M'):
            multiplier = 1_000_000
            text = text[:-1]

        try:
            return float(text) * multiplier
        except (ValueError, AttributeError):
            return None

    @staticmethod
    def _get_text(soup, selector: str) -> Optional[str]:
        """Safely extract text from element."""
        elem = soup.select_one(selector)
        return elem.get_text(strip=True) if elem else None


# Example usage
if __name__ == "__main__":
    with BizBuySellScraper() as scraper:
        # Scrape California businesses under $2M
        listings = scraper.scrape(
            state='CA',
            max_price=2_000_000,
            max_pages=5
        )

        for listing in listings:
            print(f"{listing.title} - ${listing.asking_price:,.0f} - {listing.location}")
