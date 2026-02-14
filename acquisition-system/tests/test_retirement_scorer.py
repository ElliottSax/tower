"""Tests for retirement likelihood scoring model."""

import pytest
from datetime import date, datetime

from backend.models.retirement_scorer import RetirementScorer


class TestFeatureExtraction:
    """Test feature extraction from business data."""

    def setup_method(self):
        self.scorer = RetirementScorer()

    def test_extract_owner_age_features(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)

        assert features['owner_age'] == 67
        assert features['owner_age_55_plus'] == 1
        assert features['owner_age_65_plus'] == 1
        assert features['owner_age_75_plus'] == 0

    def test_extract_young_owner(self, cold_lead_data):
        features = self.scorer.extract_features(cold_lead_data)

        assert features['owner_age'] == 35
        assert features['owner_age_55_plus'] == 0
        assert features['owner_age_65_plus'] == 0
        assert features['owner_age_75_plus'] == 0

    def test_extract_business_tenure(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)

        # Business from 2005 = ~21 years
        assert features['years_in_business'] > 20
        assert features['business_tenure_15_plus'] == 1
        assert features['business_tenure_20_plus'] == 1

    def test_extract_tenure_no_incorporation_date(self):
        data = {'owner_age': 50}
        features = self.scorer.extract_features(data)

        assert features['years_in_business'] == 0
        assert features['business_tenure_15_plus'] == 0

    def test_marketplace_listing_signal(self, hot_lead_data):
        features = self.scorer.extract_features(hot_lead_data)
        assert features['active_marketplace_listing'] == 1

    def test_no_marketplace_listing(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)
        assert features['active_marketplace_listing'] == 0

    def test_headcount_decline(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)

        # 18 -> 15 employees = 16.7% decline
        assert features['headcount_decline_pct'] > 0.10
        assert features['headcount_decline'] == 1

    def test_no_headcount_decline(self, cold_lead_data):
        features = self.scorer.extract_features(cold_lead_data)

        # 4 -> 5 = growth, not decline
        assert features['headcount_decline_pct'] == 0
        assert features['headcount_decline'] == 0

    def test_digital_decay_signals(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)

        assert features['website_outdated'] == 1  # 2023 > 365 days ago
        assert features['linkedin_inactive'] == 1  # 120 days > 90

    def test_revenue_buckets(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)

        assert features['revenue_1m_to_5m'] == 1
        assert features['revenue_under_1m'] == 0
        assert features['revenue_5m_plus'] == 0

    def test_entity_type_detection(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)
        assert features['entity_llc'] == 1
        assert features['entity_c_corp'] == 0

    def test_high_exit_industry(self):
        data = {'industry': 'Restaurant', 'owner_age': 50}
        features = self.scorer.extract_features(data)
        assert features['high_exit_industry'] == 1

    def test_succession_plan(self, cold_lead_data):
        features = self.scorer.extract_features(cold_lead_data)
        assert features['no_succession_plan'] == 0  # has_succession_plan = True

    def test_no_succession_plan(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)
        assert features['no_succession_plan'] == 1


class TestScoring:
    """Test retirement likelihood scoring."""

    def setup_method(self):
        self.scorer = RetirementScorer()

    def test_hot_lead_scores_high(self, hot_lead_data):
        features = self.scorer.extract_features(hot_lead_data)
        score, signals = self.scorer.calculate_score(features)

        assert score >= 0.70, f"Hot lead should score >= 0.70, got {score}"

    def test_cold_lead_scores_low(self, cold_lead_data):
        features = self.scorer.extract_features(cold_lead_data)
        score, signals = self.scorer.calculate_score(features)

        assert score < 0.45, f"Cold lead should score < 0.45, got {score}"

    def test_score_between_0_and_1(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)
        score, signals = self.scorer.calculate_score(features)

        assert 0.0 <= score <= 1.0

    def test_signals_returned(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)
        score, signals = self.scorer.calculate_score(features)

        expected_keys = {
            'marketplace_listing', 'owner_age', 'business_tenure',
            'pe_hold_period', 'digital_decay', 'headcount_decline',
            'no_succession_plan'
        }
        assert set(signals.keys()) == expected_keys

    def test_all_signals_normalized(self, sample_business_data):
        features = self.scorer.extract_features(sample_business_data)
        score, signals = self.scorer.calculate_score(features)

        for name, value in signals.items():
            assert 0.0 <= value <= 1.0, f"Signal {name} = {value} is out of range"

    def test_marketplace_listing_boosts_score(self, sample_business_data):
        features_without = self.scorer.extract_features(sample_business_data)
        score_without, _ = self.scorer.calculate_score(features_without)

        sample_business_data['bizbuysell_listing'] = True
        features_with = self.scorer.extract_features(sample_business_data)
        score_with, _ = self.scorer.calculate_score(features_with)

        assert score_with > score_without

    def test_empty_data_doesnt_crash(self):
        features = self.scorer.extract_features({})
        score, signals = self.scorer.calculate_score(features)

        assert score >= 0.0
        assert isinstance(signals, dict)


class TestModelPersistence:
    """Test model save/load."""

    def test_no_model_uses_rule_based(self):
        scorer = RetirementScorer()
        assert scorer.model is None

    def test_model_version(self):
        scorer = RetirementScorer()
        assert scorer.model_version == "1.0"
