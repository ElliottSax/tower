"""Tests for website analyzer / digital decay detection."""

import pytest
from datetime import date, datetime
from unittest.mock import MagicMock, patch
from bs4 import BeautifulSoup

from backend.scrapers.website_analyzer import WebsiteAnalysis, WebsiteAnalyzer


class TestWebsiteAnalysis:
    """Test WebsiteAnalysis dataclass."""

    def test_default_values(self):
        analysis = WebsiteAnalysis(url="https://example.com")
        assert analysis.is_reachable is False
        assert analysis.ssl_valid is False
        assert analysis.decay_score == 0.0
        assert analysis.technologies == []

    def test_to_dict(self):
        analysis = WebsiteAnalysis(
            url="https://example.com",
            is_reachable=True,
            ssl_valid=True,
            copyright_year=2024,
            cms="WordPress",
        )
        d = analysis.to_dict()
        assert d['url'] == "https://example.com"
        assert d['ssl_valid'] is True
        assert d['copyright_year'] == 2024
        assert d['cms'] == "WordPress"


class TestCopyrightYearDetection:
    """Test copyright year extraction from HTML."""

    def setup_method(self):
        self.analyzer = WebsiteAnalyzer()

    def test_simple_copyright(self):
        html = '<footer>© 2024 Acme Corp</footer>'
        soup = BeautifulSoup(html, 'html.parser')
        year = self.analyzer._find_copyright_year(soup, html)
        assert year == 2024

    def test_copyright_with_range(self):
        html = '<footer>© 2010-2024 Acme Corp</footer>'
        soup = BeautifulSoup(html, 'html.parser')
        year = self.analyzer._find_copyright_year(soup, html)
        assert year == 2024

    def test_copyright_word_format(self):
        html = '<footer>Copyright 2023 Business Inc.</footer>'
        soup = BeautifulSoup(html, 'html.parser')
        year = self.analyzer._find_copyright_year(soup, html)
        assert year == 2023

    def test_copyright_paren_format(self):
        html = '<footer>(c) 2022 Old Business</footer>'
        soup = BeautifulSoup(html, 'html.parser')
        year = self.analyzer._find_copyright_year(soup, html)
        assert year == 2022

    def test_no_copyright(self):
        html = '<footer>Contact us at info@example.com</footer>'
        soup = BeautifulSoup(html, 'html.parser')
        year = self.analyzer._find_copyright_year(soup, html)
        assert year is None

    def test_rejects_invalid_year(self):
        html = '<footer>© 1850 Ancient Corp</footer>'
        soup = BeautifulSoup(html, 'html.parser')
        year = self.analyzer._find_copyright_year(soup, html)
        assert year is None


class TestCMSDetection:
    """Test Content Management System detection."""

    def setup_method(self):
        self.analyzer = WebsiteAnalyzer()

    def _detect(self, html, headers=None):
        soup = BeautifulSoup(html, 'html.parser')
        return self.analyzer._detect_cms(soup, html, headers or {})

    def test_detect_wordpress(self):
        html = '<link rel="stylesheet" href="/wp-content/themes/theme/style.css">'
        assert self._detect(html) == 'WordPress'

    def test_detect_squarespace(self):
        html = '<script src="https://static.squarespace.com/universal/scripts.js"></script>'
        assert self._detect(html) == 'Squarespace'

    def test_detect_wix(self):
        html = '<meta name="generator" content="Wix.com Website Builder">'
        assert self._detect(html) == 'Wix'

    def test_detect_shopify(self):
        html = '<link rel="stylesheet" href="https://cdn.shopify.com/s/files/theme.css">'
        assert self._detect(html) == 'Shopify'

    def test_detect_no_cms(self):
        html = '<html><body>Simple static page</body></html>'
        assert self._detect(html) is None


class TestAnalyticsDetection:
    """Test analytics/tracking detection."""

    def setup_method(self):
        self.analyzer = WebsiteAnalyzer()

    def test_detect_google_analytics(self):
        html = '<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXX"></script>'
        assert self.analyzer._detect_analytics(html) is True

    def test_detect_gtm(self):
        html = '<script>(function(w,d,s,l){...})(window,document,"script","dataLayer");</script>'
        # "gtm.js" not present in this snippet; just test the pattern matching
        html2 = 'src="https://www.googletagmanager.com/gtm.js?id=GTM-XXXX"'
        assert self.analyzer._detect_analytics(html2) is True

    def test_no_analytics(self):
        html = '<html><body>No tracking here</body></html>'
        assert self.analyzer._detect_analytics(html) is False

    def test_detect_hotjar(self):
        html = '<script>...hotjar...</script>'
        assert self.analyzer._detect_analytics(html) is True


class TestSocialLinks:
    """Test social media link extraction."""

    def setup_method(self):
        self.analyzer = WebsiteAnalyzer()

    def test_find_facebook(self):
        html = '<a href="https://www.facebook.com/acmecorp">Facebook</a>'
        soup = BeautifulSoup(html, 'html.parser')
        links = self.analyzer._find_social_links(soup)
        assert 'facebook' in links

    def test_find_multiple_social(self):
        html = '''
        <a href="https://facebook.com/biz">FB</a>
        <a href="https://linkedin.com/company/biz">LI</a>
        <a href="https://x.com/biz">X</a>
        '''
        soup = BeautifulSoup(html, 'html.parser')
        links = self.analyzer._find_social_links(soup)
        assert 'facebook' in links
        assert 'linkedin' in links
        assert 'twitter' in links  # x.com maps to twitter

    def test_no_social_links(self):
        html = '<a href="/about">About</a>'
        soup = BeautifulSoup(html, 'html.parser')
        links = self.analyzer._find_social_links(soup)
        assert len(links) == 0


class TestDecayScoring:
    """Test decay score calculation."""

    def setup_method(self):
        self.analyzer = WebsiteAnalyzer()

    def test_unreachable_site_high_decay(self):
        analysis = WebsiteAnalysis(url="https://example.com", is_reachable=False)
        self.analyzer._calculate_decay_score(analysis)
        assert analysis.decay_score >= 0.8

    def test_fresh_modern_site_low_decay(self):
        analysis = WebsiteAnalysis(
            url="https://example.com",
            is_reachable=True,
            ssl_valid=True,
            ssl_days_remaining=300,
            copyright_year=datetime.now().year,
            mobile_responsive=True,
            has_analytics=True,
            has_blog=True,
            blog_last_post_date=date.today(),
        )
        self.analyzer._calculate_decay_score(analysis)
        assert analysis.decay_score < 0.2

    def test_outdated_site_high_decay(self):
        analysis = WebsiteAnalysis(
            url="https://example.com",
            is_reachable=True,
            ssl_valid=False,
            copyright_year=2018,
            mobile_responsive=False,
            has_analytics=False,
            cms='GoDaddy',
        )
        self.analyzer._calculate_decay_score(analysis)
        assert analysis.decay_score > 0.5

    def test_decay_factors_populated(self):
        analysis = WebsiteAnalysis(
            url="https://example.com",
            is_reachable=True,
            ssl_valid=True,
            ssl_days_remaining=300,
        )
        self.analyzer._calculate_decay_score(analysis)
        assert len(analysis.decay_factors) > 0
