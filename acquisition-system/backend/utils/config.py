"""
Configuration management using pydantic-settings.
Loads from environment variables and .env files.
"""

from pathlib import Path
from typing import Optional, List
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=Path(__file__).parent.parent.parent / "config" / ".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )

    # Database
    database_url: str = Field(..., description="PostgreSQL connection string")
    supabase_url: Optional[str] = None
    supabase_anon_key: Optional[str] = None
    supabase_service_key: Optional[str] = None

    # AI & Personalization
    anthropic_api_key: str = Field(..., description="Claude API key")
    claude_model: str = "claude-sonnet-4-5-20250929"
    claude_use_batch: bool = True
    openai_api_key: Optional[str] = None

    # Data Sources - Secretary of State
    ca_sos_api_key: Optional[str] = None
    ia_sos_api_key: Optional[str] = None
    ia_sos_api_url: Optional[str] = None
    cobalt_api_key: Optional[str] = None
    middesk_api_key: Optional[str] = None

    # Data Sources - Other
    proxycurl_api_key: Optional[str] = None
    bizbuysell_scraper_enabled: bool = True

    # Data Enrichment
    prospeo_api_key: Optional[str] = None
    dropcontact_api_key: Optional[str] = None
    datagma_api_key: Optional[str] = None
    hunter_api_key: Optional[str] = None
    apollo_api_key: Optional[str] = None
    clearbit_api_key: Optional[str] = None

    # Email Automation
    instantly_api_key: Optional[str] = None
    instantly_campaign_id: Optional[str] = None
    smartlead_api_key: Optional[str] = None
    zerobounce_api_key: Optional[str] = None
    neverbounce_api_key: Optional[str] = None

    # Email Configuration
    outreach_domain: str = "example.com"
    outreach_from_name: str = "John Doe"
    outreach_from_email: str = "john@example.com"
    warmup_daily_limit_start: int = 10
    warmup_daily_limit_max: int = 50
    warmup_increment_days: int = 3

    # Web Scraping
    proxy_url: Optional[str] = None
    proxy_username: Optional[str] = None
    proxy_password: Optional[str] = None
    scraper_rate_limit: float = 0.5
    scraper_user_agent: str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

    # Machine Learning - Feature Weights
    score_weight_marketplace_listing: float = 0.30
    score_weight_owner_age_65_plus: float = 0.20
    score_weight_business_tenure_20_plus: float = 0.15
    score_weight_pe_hold_period: float = 0.12
    score_weight_digital_decay: float = 0.10
    score_weight_headcount_decline: float = 0.08
    score_weight_no_succession_plan: float = 0.05

    # Scoring Thresholds
    score_threshold_hot: float = 0.70
    score_threshold_warm: float = 0.45

    # Paths
    training_data_path: Path = Path("./data/training/")
    model_output_path: Path = Path("./data/models/")

    # Webhooks & Notifications
    discord_webhook_url: Optional[str] = None
    slack_webhook_url: Optional[str] = None
    notify_new_hot_leads: bool = True
    notify_responses: bool = True
    notify_errors: bool = True

    # Monitoring
    sentry_dsn: Optional[str] = None
    sentry_environment: str = "development"
    sentry_traces_sample_rate: float = 0.1

    # Cron Schedules
    cron_sos_sync: str = "0 2 * * *"
    cron_enrichment: str = "0 3 * * *"
    cron_scoring: str = "0 4 * * *"
    cron_email_verification: str = "0 5 * * 0"
    cron_outreach: str = "0 9 * * 1-5"
    cron_reverify: str = "0 6 1 */3 *"

    # General
    debug: bool = False
    log_level: str = "INFO"

    @field_validator('training_data_path', 'model_output_path')
    @classmethod
    def ensure_path_exists(cls, v: Path) -> Path:
        """Create directories if they don't exist."""
        v.mkdir(parents=True, exist_ok=True)
        return v

    def get_enrichment_providers(self) -> List[str]:
        """Return list of configured enrichment providers in waterfall order."""
        providers = []
        if self.prospeo_api_key:
            providers.append("prospeo")
        if self.dropcontact_api_key:
            providers.append("dropcontact")
        if self.datagma_api_key:
            providers.append("datagma")
        if self.hunter_api_key:
            providers.append("hunter")
        if self.apollo_api_key:
            providers.append("apollo")
        return providers

    def get_feature_weights(self) -> dict[str, float]:
        """Return feature weights as a dictionary keyed by signal name."""
        return {
            "marketplace_listing": self.score_weight_marketplace_listing,
            "owner_age": self.score_weight_owner_age_65_plus,
            "business_tenure": self.score_weight_business_tenure_20_plus,
            "pe_hold_period": self.score_weight_pe_hold_period,
            "digital_decay": self.score_weight_digital_decay,
            "headcount_decline": self.score_weight_headcount_decline,
            "no_succession_plan": self.score_weight_no_succession_plan,
        }


# Global settings instance
settings = Settings()
