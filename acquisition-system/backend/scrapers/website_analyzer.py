"""
Website metadata analyzer for digital decay detection.
Checks website freshness, SSL, technology stack, copyright dates.
Feeds into scoring model's digital_decay signal.
"""

import re
import ssl
import socket
from typing import Dict, Optional, List
from datetime import datetime, date
from dataclasses import dataclass, field
from urllib.parse import urlparse

from .base import BaseScraper, PlaywrightScraper
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


@dataclass
class WebsiteAnalysis:
    """Results of website analysis."""
    url: str

    # Availability
    is_reachable: bool = False
    http_status: Optional[int] = None
    redirect_url: Optional[str] = None

    # SSL/Security
    ssl_valid: bool = False
    ssl_expiry_date: Optional[date] = None
    ssl_days_remaining: Optional[int] = None

    # Freshness signals
    copyright_year: Optional[int] = None
    last_modified_header: Optional[str] = None
    meta_last_updated: Optional[str] = None
    newest_content_date: Optional[date] = None

    # Technology signals
    cms: Optional[str] = None  # WordPress, Squarespace, Wix, etc.
    technologies: List[str] = field(default_factory=list)
    has_analytics: bool = False
    has_structured_data: bool = False
    mobile_responsive: bool = False

    # Content quality
    has_blog: bool = False
    blog_last_post_date: Optional[date] = None
    page_count_estimate: int = 0
    broken_links_count: int = 0

    # Social presence
    social_links: Dict[str, str] = field(default_factory=dict)

    # Scoring
    decay_score: float = 0.0  # 0 = fresh, 1 = completely decayed
    decay_factors: Dict[str, float] = field(default_factory=dict)

    # Metadata
    analyzed_at: datetime = field(default_factory=datetime.now)

    def to_dict(self) -> Dict:
        data = {
            'url': self.url,
            'is_reachable': self.is_reachable,
            'http_status': self.http_status,
            'ssl_valid': self.ssl_valid,
            'ssl_expiry_date': self.ssl_expiry_date.isoformat() if self.ssl_expiry_date else None,
            'copyright_year': self.copyright_year,
            'cms': self.cms,
            'technologies': self.technologies,
            'has_analytics': self.has_analytics,
            'mobile_responsive': self.mobile_responsive,
            'has_blog': self.has_blog,
            'blog_last_post_date': self.blog_last_post_date.isoformat() if self.blog_last_post_date else None,
            'social_links': self.social_links,
            'decay_score': self.decay_score,
            'decay_factors': self.decay_factors,
            'analyzed_at': self.analyzed_at.isoformat(),
        }
        return data


class WebsiteAnalyzer(BaseScraper):
    """
    Analyzes website metadata to detect digital decay.

    Digital decay signals include:
    - Outdated copyright year
    - Expired/invalid SSL certificate
    - Old CMS versions
    - No recent blog posts
    - Absence of analytics/tracking
    - Non-responsive design
    - Broken links
    """

    def __init__(self):
        super().__init__(rate_limit=1.0)

    def scrape(self, url: str) -> WebsiteAnalysis:
        """Alias for analyze()."""
        return self.analyze(url)

    def analyze(self, url: str) -> WebsiteAnalysis:
        """
        Perform full website analysis.

        Args:
            url: Website URL to analyze

        Returns:
            WebsiteAnalysis with all findings
        """
        # Normalize URL
        if not url.startswith(('http://', 'https://')):
            url = f'https://{url}'

        analysis = WebsiteAnalysis(url=url)

        logger.info(f"Analyzing website: {url}")

        try:
            # 1. Check SSL certificate
            self._check_ssl(url, analysis)

            # 2. Fetch and analyze HTML
            self._analyze_html(url, analysis)

            # 3. Calculate decay score
            self._calculate_decay_score(analysis)

        except Exception as e:
            log_error(logger, e, {'url': url})
            analysis.decay_score = 0.5  # Unknown = moderate decay

        return analysis

    def _check_ssl(self, url: str, analysis: WebsiteAnalysis):
        """Check SSL certificate validity and expiration."""
        parsed = urlparse(url)
        hostname = parsed.hostname

        try:
            context = ssl.create_default_context()
            with socket.create_connection((hostname, 443), timeout=10) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    cert = ssock.getpeercert()

                    analysis.ssl_valid = True

                    # Parse expiry date
                    expiry_str = cert.get('notAfter')
                    if expiry_str:
                        expiry = datetime.strptime(expiry_str, '%b %d %H:%M:%S %Y %Z')
                        analysis.ssl_expiry_date = expiry.date()
                        analysis.ssl_days_remaining = (expiry.date() - date.today()).days

        except ssl.SSLError:
            analysis.ssl_valid = False
            logger.debug(f"SSL invalid for {hostname}")

        except (socket.timeout, socket.gaierror, ConnectionRefusedError, OSError):
            analysis.ssl_valid = False
            logger.debug(f"Cannot connect to {hostname}:443")

    def _analyze_html(self, url: str, analysis: WebsiteAnalysis):
        """Fetch and analyze HTML content."""
        try:
            response = self.fetch_url(url)
            analysis.is_reachable = True
            analysis.http_status = response.status_code

            # Check for redirects
            if response.url != url:
                analysis.redirect_url = response.url

            # Check Last-Modified header
            analysis.last_modified_header = response.headers.get('Last-Modified')

            html = response.text
            soup = self.parse_html(html)

            # Copyright year detection
            analysis.copyright_year = self._find_copyright_year(soup, html)

            # CMS detection
            analysis.cms = self._detect_cms(soup, html, response.headers)

            # Technology detection
            analysis.technologies = self._detect_technologies(soup, html, response.headers)

            # Analytics detection
            analysis.has_analytics = self._detect_analytics(html)

            # Structured data detection
            analysis.has_structured_data = bool(
                soup.find('script', type='application/ld+json') or
                soup.find(attrs={'itemtype': True})
            )

            # Mobile responsiveness
            viewport = soup.find('meta', attrs={'name': 'viewport'})
            analysis.mobile_responsive = viewport is not None

            # Blog detection
            self._detect_blog(soup, analysis)

            # Social links
            analysis.social_links = self._find_social_links(soup)

        except Exception as e:
            analysis.is_reachable = False
            log_error(logger, e, {'url': url})

    def _find_copyright_year(self, soup, html: str) -> Optional[int]:
        """Find copyright year in page content."""
        current_year = datetime.now().year

        # Look in footer first
        footer = soup.find('footer') or soup.find(class_=re.compile(r'footer', re.I))
        search_text = footer.get_text() if footer else html

        # Common copyright patterns
        patterns = [
            r'©\s*(\d{4})',
            r'copyright\s*(?:©)?\s*(\d{4})',
            r'\(c\)\s*(\d{4})',
            r'©\s*\d{4}\s*[-–]\s*(\d{4})',  # "© 2010-2024" → get latest year
        ]

        years = []
        for pattern in patterns:
            matches = re.findall(pattern, search_text, re.IGNORECASE)
            for match in matches:
                year = int(match)
                if 1990 <= year <= current_year:
                    years.append(year)

        return max(years) if years else None

    def _detect_cms(self, soup, html: str, headers: Dict) -> Optional[str]:
        """Detect Content Management System."""
        # WordPress
        if (soup.find('meta', attrs={'name': 'generator', 'content': re.compile(r'WordPress', re.I)}) or
                'wp-content' in html or 'wp-includes' in html):
            return 'WordPress'

        # Squarespace
        if 'squarespace' in html.lower() or 'static.squarespace.com' in html:
            return 'Squarespace'

        # Wix
        if 'wix.com' in html.lower() or '_wixCIDX' in html:
            return 'Wix'

        # Shopify
        if 'shopify' in html.lower() or 'cdn.shopify.com' in html:
            return 'Shopify'

        # Webflow
        if 'webflow' in html.lower():
            return 'Webflow'

        # Joomla
        if soup.find('meta', attrs={'name': 'generator', 'content': re.compile(r'Joomla', re.I)}):
            return 'Joomla'

        # Drupal
        if 'drupal' in html.lower() or headers.get('X-Generator', '').lower().startswith('drupal'):
            return 'Drupal'

        # GoDaddy Website Builder
        if 'godaddy' in html.lower():
            return 'GoDaddy'

        return None

    def _detect_technologies(self, soup, html: str, headers: Dict) -> List[str]:
        """Detect web technologies in use."""
        techs = []

        # jQuery
        if 'jquery' in html.lower():
            techs.append('jQuery')

        # React
        if 'react' in html.lower() or '__NEXT_DATA__' in html:
            techs.append('React')

        # Bootstrap
        if 'bootstrap' in html.lower():
            techs.append('Bootstrap')

        # Google Maps
        if 'maps.googleapis.com' in html or 'maps.google.com' in html:
            techs.append('Google Maps')

        # Server
        server = headers.get('Server', '')
        if server:
            techs.append(f'Server: {server}')

        # CDN
        if headers.get('CF-Ray'):
            techs.append('Cloudflare')
        elif 'fastly' in headers.get('Via', '').lower():
            techs.append('Fastly')

        return techs

    def _detect_analytics(self, html: str) -> bool:
        """Detect analytics/tracking scripts."""
        analytics_patterns = [
            'google-analytics.com',
            'googletagmanager.com',
            'gtag(',
            'ga(',
            'analytics.js',
            'gtm.js',
            'facebook.com/tr',
            'pixel',
            'hotjar',
            'clarity.ms',
        ]

        html_lower = html.lower()
        return any(pattern in html_lower for pattern in analytics_patterns)

    def _detect_blog(self, soup, analysis: WebsiteAnalysis):
        """Detect blog presence and recency."""
        # Look for blog links
        blog_links = soup.find_all('a', href=re.compile(r'/blog|/news|/articles|/insights', re.I))
        analysis.has_blog = len(blog_links) > 0

        # Look for article dates
        date_patterns = [
            re.compile(r'(\d{4}-\d{2}-\d{2})'),
            re.compile(r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},?\s+\d{4}', re.I),
        ]

        article_elements = soup.find_all(['article', 'time', 'span'], class_=re.compile(r'date|time|published', re.I))

        dates = []
        for elem in article_elements:
            text = elem.get_text()
            datetime_attr = elem.get('datetime', '')

            for pattern in date_patterns:
                match = pattern.search(datetime_attr or text)
                if match:
                    try:
                        date_str = match.group(0)
                        if '-' in date_str:
                            parsed = datetime.strptime(date_str, '%Y-%m-%d').date()
                        else:
                            parsed = datetime.strptime(date_str, '%B %d, %Y').date()

                        if parsed <= date.today():
                            dates.append(parsed)
                    except ValueError:
                        continue

        if dates:
            analysis.blog_last_post_date = max(dates)

    def _find_social_links(self, soup) -> Dict[str, str]:
        """Find social media links."""
        social_domains = {
            'facebook.com': 'facebook',
            'twitter.com': 'twitter',
            'x.com': 'twitter',
            'linkedin.com': 'linkedin',
            'instagram.com': 'instagram',
            'youtube.com': 'youtube',
            'yelp.com': 'yelp',
            'tiktok.com': 'tiktok',
        }

        links = {}
        for a_tag in soup.find_all('a', href=True):
            href = a_tag['href'].lower()
            for domain, name in social_domains.items():
                if domain in href and name not in links:
                    links[name] = a_tag['href']

        return links

    def _calculate_decay_score(self, analysis: WebsiteAnalysis):
        """
        Calculate overall digital decay score (0 = fresh, 1 = decayed).
        This score feeds directly into the retirement likelihood model.
        """
        factors = {}
        current_year = datetime.now().year

        # 1. Website unreachable (strong decay signal)
        if not analysis.is_reachable:
            factors['unreachable'] = 1.0
            analysis.decay_score = 0.9
            analysis.decay_factors = factors
            return

        # 2. SSL certificate
        if not analysis.ssl_valid:
            factors['ssl_invalid'] = 1.0
        elif analysis.ssl_days_remaining is not None and analysis.ssl_days_remaining < 30:
            factors['ssl_expiring'] = 0.5
        else:
            factors['ssl_valid'] = 0.0

        # 3. Copyright year freshness
        if analysis.copyright_year:
            years_old = current_year - analysis.copyright_year
            if years_old >= 3:
                factors['copyright_outdated'] = min(1.0, years_old / 5.0)
            elif years_old >= 1:
                factors['copyright_stale'] = 0.3
            else:
                factors['copyright_current'] = 0.0
        else:
            factors['copyright_missing'] = 0.4  # No copyright = moderate signal

        # 4. Mobile responsiveness
        if not analysis.mobile_responsive:
            factors['not_mobile'] = 0.7  # Strong signal of neglect

        # 5. Analytics/tracking
        if not analysis.has_analytics:
            factors['no_analytics'] = 0.5

        # 6. Blog freshness
        if analysis.has_blog and analysis.blog_last_post_date:
            days_since_post = (date.today() - analysis.blog_last_post_date).days
            if days_since_post > 365:
                factors['blog_abandoned'] = min(1.0, days_since_post / 730.0)
            elif days_since_post > 180:
                factors['blog_stale'] = 0.4
            else:
                factors['blog_active'] = 0.0
        elif analysis.has_blog:
            factors['blog_undated'] = 0.3

        # 7. Technology age (basic CMS on old platforms)
        if analysis.cms in ('GoDaddy', 'Joomla'):
            factors['old_platform'] = 0.3

        # Weighted average
        weights = {
            'unreachable': 0.30,
            'ssl_invalid': 0.20, 'ssl_expiring': 0.20, 'ssl_valid': 0.20,
            'copyright_outdated': 0.20, 'copyright_stale': 0.20, 'copyright_current': 0.20, 'copyright_missing': 0.20,
            'not_mobile': 0.15,
            'no_analytics': 0.10,
            'blog_abandoned': 0.10, 'blog_stale': 0.10, 'blog_active': 0.10, 'blog_undated': 0.10,
            'old_platform': 0.05,
        }

        weighted_sum = 0.0
        weight_total = 0.0

        for factor_name, factor_value in factors.items():
            weight = weights.get(factor_name, 0.05)
            weighted_sum += factor_value * weight
            weight_total += weight

        analysis.decay_score = round(weighted_sum / max(weight_total, 0.01), 4)
        analysis.decay_factors = factors


def batch_analyze(urls: List[str]) -> List[WebsiteAnalysis]:
    """
    Analyze multiple websites.

    Args:
        urls: List of website URLs

    Returns:
        List of WebsiteAnalysis results
    """
    analyzer = WebsiteAnalyzer()
    results = []

    for url in urls:
        try:
            result = analyzer.analyze(url)
            results.append(result)
            logger.info(f"Analyzed {url}: decay_score={result.decay_score:.2f}")
        except Exception as e:
            log_error(logger, e, {'url': url})
            continue

    return results


# Example usage
if __name__ == "__main__":
    analyzer = WebsiteAnalyzer()

    test_urls = [
        "https://www.example.com",
        "https://httpbin.org",
    ]

    for url in test_urls:
        result = analyzer.analyze(url)

        print(f"\n{'='*50}")
        print(f"URL: {result.url}")
        print(f"Reachable: {result.is_reachable}")
        print(f"SSL Valid: {result.ssl_valid} (expires: {result.ssl_expiry_date})")
        print(f"Copyright Year: {result.copyright_year}")
        print(f"CMS: {result.cms}")
        print(f"Mobile Responsive: {result.mobile_responsive}")
        print(f"Has Analytics: {result.has_analytics}")
        print(f"Has Blog: {result.has_blog}")
        print(f"Social Links: {result.social_links}")
        print(f"\nDecay Score: {result.decay_score:.2f}")
        print(f"Decay Factors: {result.decay_factors}")
