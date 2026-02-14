"""
LinkedIn enrichment via Proxycurl API.
Extracts company data, owner profiles, age estimation, and headcount tracking.
"""

from typing import Dict, Optional, List
from datetime import datetime, date
from dataclasses import dataclass, field

from ..scrapers.base import APIScraper
from ..utils.config import settings
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


@dataclass
class LinkedInCompanyProfile:
    """Company data from LinkedIn."""
    name: str
    linkedin_url: str
    description: Optional[str] = None
    website: Optional[str] = None
    industry: Optional[str] = None
    company_size_min: Optional[int] = None
    company_size_max: Optional[int] = None
    follower_count: Optional[int] = None
    founded_year: Optional[int] = None
    specialties: List[str] = field(default_factory=list)
    locations: List[Dict] = field(default_factory=list)
    similar_companies: List[str] = field(default_factory=list)
    raw_data: Dict = field(default_factory=dict)


@dataclass
class LinkedInPersonProfile:
    """Person data from LinkedIn."""
    full_name: str
    linkedin_url: str
    headline: Optional[str] = None
    summary: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None

    # Current position
    current_company: Optional[str] = None
    current_title: Optional[str] = None
    current_company_start_date: Optional[date] = None

    # Age estimation
    estimated_birth_year: Optional[int] = None
    estimated_age: Optional[int] = None
    age_confidence: float = 0.0  # 0-1

    # Education
    earliest_education_year: Optional[int] = None
    education: List[Dict] = field(default_factory=list)

    # Experience
    total_experience_years: Optional[float] = None
    experiences: List[Dict] = field(default_factory=list)

    # Metadata
    raw_data: Dict = field(default_factory=dict)


class LinkedInEnricher:
    """
    LinkedIn enrichment using Proxycurl API ($0.01/profile).

    Provides:
    - Company data (size, industry, specialties)
    - Owner profiles (title, tenure)
    - Age estimation (from education/career history)
    - Headcount tracking
    """

    PROXYCURL_BASE = "https://nubela.co/proxycurl/api"

    def __init__(self):
        if not settings.proxycurl_api_key:
            raise ValueError("PROXYCURL_API_KEY not configured")

        self.api = APIScraper(
            api_key=settings.proxycurl_api_key,
            base_url=self.PROXYCURL_BASE,
            rate_limit=1.0  # Respect API rate limits
        )

        # Override auth header - Proxycurl uses Bearer token
        self.api.session.headers['Authorization'] = f'Bearer {settings.proxycurl_api_key}'

        logger.info("Initialized LinkedIn enrichment via Proxycurl")

    def enrich_company(self, linkedin_url: str) -> Optional[LinkedInCompanyProfile]:
        """
        Enrich company data from LinkedIn URL.

        Args:
            linkedin_url: LinkedIn company page URL

        Returns:
            LinkedInCompanyProfile or None on failure
        """
        logger.info(f"Enriching company: {linkedin_url}")

        try:
            data = self.api.api_get("linkedin/company", params={
                'url': linkedin_url,
                'use_cache': 'if-present',
            })

            if not data or 'name' not in data:
                logger.warning(f"No data returned for {linkedin_url}")
                return None

            # Parse company size
            size_range = data.get('company_size', [None, None])
            size_min = size_range[0] if isinstance(size_range, list) and len(size_range) > 0 else None
            size_max = size_range[1] if isinstance(size_range, list) and len(size_range) > 1 else None

            return LinkedInCompanyProfile(
                name=data.get('name', ''),
                linkedin_url=linkedin_url,
                description=data.get('description'),
                website=data.get('website'),
                industry=data.get('industry'),
                company_size_min=size_min,
                company_size_max=size_max,
                follower_count=data.get('follower_count'),
                founded_year=data.get('founded_year'),
                specialties=data.get('specialities', []) or [],
                locations=data.get('locations', []) or [],
                similar_companies=[c.get('link') for c in (data.get('similar_companies', []) or []) if c.get('link')],
                raw_data=data,
            )

        except Exception as e:
            log_error(logger, e, {'linkedin_url': linkedin_url})
            return None

    def enrich_person(self, linkedin_url: str) -> Optional[LinkedInPersonProfile]:
        """
        Enrich person data from LinkedIn URL.

        Args:
            linkedin_url: LinkedIn person profile URL

        Returns:
            LinkedInPersonProfile or None on failure
        """
        logger.info(f"Enriching person: {linkedin_url}")

        try:
            data = self.api.api_get("v2/linkedin", params={
                'url': linkedin_url,
                'use_cache': 'if-present',
                'skills': 'exclude',
                'inferred_salary': 'exclude',
                'personal_email': 'include',
                'personal_contact_number': 'include',
            })

            if not data or 'full_name' not in data:
                logger.warning(f"No data returned for {linkedin_url}")
                return None

            profile = LinkedInPersonProfile(
                full_name=data.get('full_name', ''),
                linkedin_url=linkedin_url,
                headline=data.get('headline'),
                summary=data.get('summary'),
                city=data.get('city'),
                state=data.get('state'),
                country=data.get('country_full_name'),
                raw_data=data,
            )

            # Parse experiences
            experiences = data.get('experiences', []) or []
            for exp in experiences:
                parsed_exp = {
                    'company': exp.get('company'),
                    'title': exp.get('title'),
                    'start_date': self._parse_date(exp.get('starts_at')),
                    'end_date': self._parse_date(exp.get('ends_at')),
                    'is_current': exp.get('ends_at') is None,
                }
                profile.experiences.append(parsed_exp)

                # Set current position
                if parsed_exp['is_current'] and not profile.current_company:
                    profile.current_company = parsed_exp['company']
                    profile.current_title = parsed_exp['title']
                    profile.current_company_start_date = parsed_exp['start_date']

            # Parse education
            education = data.get('education', []) or []
            years = []
            for edu in education:
                start = edu.get('starts_at')
                end = edu.get('ends_at')

                parsed_edu = {
                    'school': edu.get('school'),
                    'degree': edu.get('degree_name'),
                    'field': edu.get('field_of_study'),
                    'start_year': start.get('year') if start else None,
                    'end_year': end.get('year') if end else None,
                }
                profile.education.append(parsed_edu)

                if parsed_edu['start_year']:
                    years.append(parsed_edu['start_year'])
                if parsed_edu['end_year']:
                    years.append(parsed_edu['end_year'])

            if years:
                profile.earliest_education_year = min(years)

            # Calculate total experience
            if experiences:
                earliest_start = None
                for exp in profile.experiences:
                    if exp['start_date'] and (earliest_start is None or exp['start_date'] < earliest_start):
                        earliest_start = exp['start_date']

                if earliest_start:
                    profile.total_experience_years = (date.today() - earliest_start).days / 365.25

            # Estimate age
            self._estimate_age(profile)

            return profile

        except Exception as e:
            log_error(logger, e, {'linkedin_url': linkedin_url})
            return None

    def lookup_person(
        self,
        first_name: str,
        last_name: str,
        company_name: Optional[str] = None,
        company_domain: Optional[str] = None
    ) -> Optional[LinkedInPersonProfile]:
        """
        Find and enrich a person by name and company.

        Args:
            first_name: Person's first name
            last_name: Person's last name
            company_name: Company name
            company_domain: Company website domain

        Returns:
            LinkedInPersonProfile or None
        """
        logger.info(f"Looking up: {first_name} {last_name} at {company_name or company_domain}")

        try:
            # Use Person Lookup endpoint
            params = {
                'first_name': first_name,
                'last_name': last_name,
            }

            if company_domain:
                params['company_domain'] = company_domain
            elif company_name:
                params['company_name'] = company_name

            data = self.api.api_get("linkedin/profile/resolve", params=params)

            if data and data.get('url'):
                # Found profile, now enrich it
                return self.enrich_person(data['url'])

            logger.info(f"No LinkedIn profile found for {first_name} {last_name}")
            return None

        except Exception as e:
            log_error(logger, e, {
                'name': f"{first_name} {last_name}",
                'company': company_name or company_domain
            })
            return None

    def get_company_headcount(self, linkedin_url: str) -> Optional[Dict]:
        """
        Get employee count history for headcount trend analysis.

        Args:
            linkedin_url: LinkedIn company page URL

        Returns:
            Dict with headcount data or None
        """
        try:
            data = self.api.api_get("linkedin/company/employees/count", params={
                'url': linkedin_url,
            })

            if data:
                return {
                    'total_employees': data.get('total_employee_count'),
                    'linkedin_employees': data.get('linkedin_employee_count'),
                }

            return None

        except Exception as e:
            log_error(logger, e, {'linkedin_url': linkedin_url})
            return None

    def _estimate_age(self, profile: LinkedInPersonProfile):
        """
        Estimate person's age from education and career history.

        Heuristics:
        - College start = ~18 years old
        - College graduation = ~22 years old
        - First professional role = ~22-25 years old
        - Total experience years + 22 = approximate age
        """
        current_year = datetime.now().year
        estimates = []

        # Method 1: Earliest education year (usually college start at ~18)
        if profile.earliest_education_year:
            estimated_birth = profile.earliest_education_year - 18
            estimates.append(('education', current_year - estimated_birth, 0.6))

        # Method 2: First job start (usually ~22-25)
        if profile.experiences:
            earliest_job_year = None
            for exp in profile.experiences:
                if exp['start_date']:
                    year = exp['start_date'].year
                    if earliest_job_year is None or year < earliest_job_year:
                        earliest_job_year = year

            if earliest_job_year:
                estimated_birth = earliest_job_year - 23
                estimates.append(('career_start', current_year - estimated_birth, 0.5))

        # Method 3: Total experience + 22
        if profile.total_experience_years:
            estimated_age = profile.total_experience_years + 22
            estimates.append(('experience', estimated_age, 0.4))

        if not estimates:
            return

        # Weighted average of estimates
        total_weight = sum(e[2] for e in estimates)
        weighted_age = sum(e[1] * e[2] for e in estimates) / total_weight

        profile.estimated_age = round(weighted_age)
        profile.estimated_birth_year = current_year - profile.estimated_age
        profile.age_confidence = min(0.8, total_weight / len(estimates))

        logger.debug(
            f"Age estimate for {profile.full_name}: ~{profile.estimated_age} "
            f"(confidence: {profile.age_confidence:.2f}, methods: {[e[0] for e in estimates]})"
        )

    @staticmethod
    def _parse_date(date_dict: Optional[Dict]) -> Optional[date]:
        """Parse Proxycurl date dict to Python date."""
        if not date_dict:
            return None

        year = date_dict.get('year')
        month = date_dict.get('month', 1)
        day = date_dict.get('day', 1)

        if year:
            try:
                return date(year, month or 1, day or 1)
            except (ValueError, TypeError):
                return date(year, 1, 1)

        return None


# Example usage
if __name__ == "__main__":
    enricher = LinkedInEnricher()

    # Enrich company
    company = enricher.enrich_company("https://www.linkedin.com/company/example")
    if company:
        print(f"Company: {company.name}")
        print(f"Industry: {company.industry}")
        print(f"Size: {company.company_size_min}-{company.company_size_max}")
        print(f"Founded: {company.founded_year}")

    # Lookup and enrich person
    person = enricher.lookup_person(
        first_name="John",
        last_name="Smith",
        company_name="Smith HVAC"
    )

    if person:
        print(f"\nPerson: {person.full_name}")
        print(f"Title: {person.current_title}")
        print(f"Company: {person.current_company}")
        print(f"Estimated Age: {person.estimated_age} (confidence: {person.age_confidence:.2f})")
        print(f"Total Experience: {person.total_experience_years:.1f} years")
