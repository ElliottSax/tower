"""
Base scraper class with rate limiting, retry logic, and error handling.
"""

import time
import random
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any
from datetime import datetime

import requests
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright, Browser, Page
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

from ..utils.config import settings
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


class BaseScraper(ABC):
    """Base class for all scrapers with common functionality."""

    def __init__(
        self,
        rate_limit: Optional[float] = None,
        user_agent: Optional[str] = None,
        use_proxy: bool = False
    ):
        """
        Initialize scraper.

        Args:
            rate_limit: Seconds between requests (default from settings)
            user_agent: User agent string (default from settings)
            use_proxy: Whether to use proxy
        """
        self.rate_limit = rate_limit or settings.scraper_rate_limit
        self.user_agent = user_agent or settings.scraper_user_agent
        self.use_proxy = use_proxy and bool(settings.proxy_url)

        self.last_request_time = 0
        self.request_count = 0
        self.error_count = 0

        self.session = self._create_session()

    def _create_session(self) -> requests.Session:
        """Create requests session with headers and proxy."""
        session = requests.Session()
        session.headers.update({
            'User-Agent': self.user_agent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        })

        if self.use_proxy:
            proxies = {
                'http': settings.proxy_url,
                'https': settings.proxy_url
            }
            if settings.proxy_username and settings.proxy_password:
                auth = f"{settings.proxy_username}:{settings.proxy_password}"
                proxies = {
                    'http': f'http://{auth}@{settings.proxy_url}',
                    'https': f'http://{auth}@{settings.proxy_url}'
                }
            session.proxies.update(proxies)

        return session

    def _rate_limit_wait(self):
        """Enforce rate limiting between requests."""
        if self.rate_limit > 0:
            elapsed = time.time() - self.last_request_time
            if elapsed < self.rate_limit:
                wait_time = self.rate_limit - elapsed + random.uniform(0, 0.5)
                time.sleep(wait_time)

        self.last_request_time = time.time()

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type((requests.RequestException, ConnectionError))
    )
    def fetch_url(self, url: str, params: Optional[Dict] = None) -> requests.Response:
        """
        Fetch URL with rate limiting and retry logic.

        Args:
            url: URL to fetch
            params: Query parameters

        Returns:
            Response object

        Raises:
            requests.RequestException: On request failure after retries
        """
        self._rate_limit_wait()

        try:
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            self.request_count += 1
            return response

        except requests.RequestException as e:
            self.error_count += 1
            logger.error(f"Request failed for {url}: {e}")
            raise

    def parse_html(self, html: str) -> BeautifulSoup:
        """
        Parse HTML with BeautifulSoup.

        Args:
            html: HTML string

        Returns:
            BeautifulSoup object
        """
        return BeautifulSoup(html, 'lxml')

    @abstractmethod
    def scrape(self, *args, **kwargs) -> Any:
        """
        Main scraping method - must be implemented by subclasses.
        """
        pass

    def get_stats(self) -> Dict[str, int]:
        """Return scraper statistics."""
        return {
            'total_requests': self.request_count,
            'errors': self.error_count,
            'success_rate': round((self.request_count - self.error_count) / max(self.request_count, 1) * 100, 2)
        }

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.session.close()


class PlaywrightScraper(BaseScraper):
    """Scraper using Playwright for JavaScript-heavy sites."""

    def __init__(self, *args, headless: bool = True, **kwargs):
        """
        Initialize Playwright scraper.

        Args:
            headless: Run browser in headless mode
        """
        super().__init__(*args, **kwargs)
        self.headless = headless
        self.playwright = None
        self.browser: Optional[Browser] = None

    def __enter__(self):
        self.playwright = sync_playwright().start()
        self.browser = self.playwright.chromium.launch(
            headless=self.headless,
            proxy={
                'server': settings.proxy_url,
                'username': settings.proxy_username,
                'password': settings.proxy_password
            } if self.use_proxy else None
        )
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.browser:
            self.browser.close()
        if self.playwright:
            self.playwright.stop()
        super().__exit__(exc_type, exc_val, exc_tb)

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    def fetch_page(self, url: str) -> str:
        """
        Fetch page content using Playwright.

        Args:
            url: URL to fetch

        Returns:
            Page HTML content
        """
        self._rate_limit_wait()

        try:
            page: Page = self.browser.new_page()
            page.set_extra_http_headers({
                'User-Agent': self.user_agent
            })

            page.goto(url, wait_until='networkidle', timeout=30000)
            content = page.content()

            page.close()

            self.request_count += 1
            return content

        except Exception as e:
            self.error_count += 1
            logger.error(f"Playwright fetch failed for {url}: {e}")
            raise

    @abstractmethod
    def scrape(self, *args, **kwargs) -> Any:
        """Main scraping method - must be implemented by subclasses."""
        pass


class APIScraper(BaseScraper):
    """Base scraper for APIs with authentication."""

    def __init__(self, api_key: str, base_url: str, *args, **kwargs):
        """
        Initialize API scraper.

        Args:
            api_key: API authentication key
            base_url: Base API URL
        """
        super().__init__(*args, **kwargs)
        self.api_key = api_key
        self.base_url = base_url.rstrip('/')

        # Add API key to session headers
        self.session.headers.update({
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        })

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type((requests.RequestException,))
    )
    def api_get(self, endpoint: str, params: Optional[Dict] = None) -> Dict:
        """
        Make GET request to API endpoint.

        Args:
            endpoint: API endpoint path
            params: Query parameters

        Returns:
            JSON response as dict

        Raises:
            requests.RequestException: On request failure
        """
        self._rate_limit_wait()

        url = f"{self.base_url}/{endpoint.lstrip('/')}"

        try:
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            self.request_count += 1
            return response.json()

        except requests.RequestException as e:
            self.error_count += 1
            logger.error(f"API GET failed for {url}: {e}")
            raise

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type((requests.RequestException,))
    )
    def api_post(self, endpoint: str, data: Optional[Dict] = None) -> Dict:
        """
        Make POST request to API endpoint.

        Args:
            endpoint: API endpoint path
            data: Request body data

        Returns:
            JSON response as dict

        Raises:
            requests.RequestException: On request failure
        """
        self._rate_limit_wait()

        url = f"{self.base_url}/{endpoint.lstrip('/')}"

        try:
            response = self.session.post(url, json=data, timeout=30)
            response.raise_for_status()
            self.request_count += 1
            return response.json()

        except requests.RequestException as e:
            self.error_count += 1
            logger.error(f"API POST failed for {url}: {e}")
            raise
