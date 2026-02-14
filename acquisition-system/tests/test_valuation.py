"""Tests for business valuation calculator."""

import pytest

from backend.models.valuation import (
    ValuationCalculator, INDUSTRY_MULTIPLES,
    SDECalculation, ValuationResult,
)


class TestSDECalculation:
    """Test Seller's Discretionary Earnings calculation."""

    def setup_method(self):
        self.calc = ValuationCalculator()

    def test_basic_sde(self):
        result = self.calc.calculate_sde(
            net_income=150_000,
            owner_salary=120_000,
        )

        assert result.sde == 270_000
        assert result.net_income == 150_000
        assert result.total_add_backs == 120_000

    def test_full_sde_calculation(self, sample_sde_inputs):
        result = self.calc.calculate_sde(**sample_sde_inputs)

        # Net income + all add-backs
        expected_add_backs = (
            120_000 +  # salary
            25_000 +   # benefits
            15_000 +   # interest
            30_000 +   # depreciation
            5_000 +    # amortization
            8_000 +    # vehicle
            1_200 +    # cell phone
            5_000 +    # travel
            20_000     # lawsuit
        )

        assert result.total_add_backs == expected_add_backs
        assert result.sde == 150_000 + expected_add_backs

    def test_sde_with_no_add_backs(self):
        result = self.calc.calculate_sde(net_income=200_000)

        assert result.sde == 200_000
        assert result.total_add_backs == 0
        assert len(result.add_backs) == 0

    def test_owner_salary_adjustment(self, sample_sde_inputs):
        result = self.calc.calculate_sde(**sample_sde_inputs)

        # Owner takes 120k, market rate is 100k, adjustment = 20k
        assert result.owner_salary_adjustment == 20_000
        assert result.normalized_owner_salary == 100_000

    def test_add_back_categories(self, sample_sde_inputs):
        result = self.calc.calculate_sde(**sample_sde_inputs)

        categories = [ab.category for ab in result.add_backs]
        assert "Owner Compensation" in categories
        assert "Owner Benefits" in categories
        assert "Interest" in categories
        assert "Depreciation" in categories


class TestValuation:
    """Test business valuation with industry multiples."""

    def setup_method(self):
        self.calc = ValuationCalculator()

    def test_hvac_valuation(self):
        result = self.calc.valuate(
            business_name="Smith HVAC",
            industry="hvac",
            sde=300_000,
        )

        # HVAC multiples: 2.20 / 2.79 / 3.50
        assert result.valuation_low == round(300_000 * 2.20, -3)
        assert result.valuation_mid == round(300_000 * 2.79, -3)
        assert result.valuation_high == round(300_000 * 3.50, -3)

    def test_unknown_industry_uses_default(self):
        result = self.calc.valuate(
            business_name="Unknown Biz",
            industry="underwater_basket_weaving",
            sde=200_000,
        )

        default = INDUSTRY_MULTIPLES['default']
        assert result.sde_multiple_mid == default['sde_multiple_mid']

    def test_revenue_cross_check(self):
        result = self.calc.valuate(
            business_name="Test Biz",
            industry="hvac",
            sde=300_000,
            revenue=2_000_000,
        )

        assert result.revenue is not None
        assert result.revenue_valuation_mid is not None
        assert result.revenue_valuation_mid > 0

    def test_valuation_with_adjustments(self):
        adjustments = [
            {'name': 'Owner Dependency', 'pct': -15},
            {'name': 'Recurring Revenue', 'pct': 10},
        ]

        result = self.calc.valuate(
            business_name="Test",
            industry="hvac",
            sde=300_000,
            adjustments=adjustments,
        )

        # Net adjustment: -5%
        base_mid = 300_000 * INDUSTRY_MULTIPLES['hvac']['sde_multiple_mid']
        expected_mid = round(base_mid * 0.95, -3)
        assert result.valuation_mid == expected_mid

    def test_valuation_result_to_dict(self):
        result = self.calc.valuate(
            business_name="Test",
            industry="hvac",
            sde=300_000,
        )

        d = result.to_dict()
        assert 'business_name' in d
        assert 'valuation_mid' in d
        assert 'multiples' in d


class TestDealStructure:
    """Test deal structure suggestions."""

    def setup_method(self):
        self.calc = ValuationCalculator()

    def test_small_deal_structure(self):
        result = self.calc.valuate("Test", "hvac", sde=100_000)

        structure = result.suggested_structure
        assert structure['buyer_equity_pct'] == 10
        assert structure['sba_loan_pct'] == 75
        assert structure['seller_note_pct'] == 15

    def test_mid_deal_structure(self):
        result = self.calc.valuate("Test", "manufacturing", sde=500_000)

        structure = result.suggested_structure
        assert 'earnout_pct' in structure
        assert structure['sba_loan_pct'] == 70

    def test_large_deal_structure(self):
        result = self.calc.valuate("Test", "manufacturing", sde=1_000_000)

        structure = result.suggested_structure
        assert 'senior_debt_pct' in structure
        assert structure['buyer_equity_pct'] == 15


class TestStandardAdjustments:
    """Test standard valuation adjustments."""

    def setup_method(self):
        self.calc = ValuationCalculator()

    def test_owner_dependency_discount(self):
        adjustments = self.calc.get_standard_adjustments(owner_dependent=True)
        assert any(a['pct'] < 0 for a in adjustments)

    def test_recurring_revenue_premium(self):
        adjustments = self.calc.get_standard_adjustments(recurring_revenue_pct=75)
        assert any(a['pct'] == 20 for a in adjustments)

    def test_customer_concentration_discount(self):
        adjustments = self.calc.get_standard_adjustments(customer_concentration_pct=35)
        assert any(a['pct'] == -15 for a in adjustments)

    def test_size_premium(self):
        adjustments = self.calc.get_standard_adjustments(revenue_millions=6)
        assert any(a['pct'] == 15 for a in adjustments)

    def test_growth_premium(self):
        adjustments = self.calc.get_standard_adjustments(growth_rate=0.20)
        assert any(a['pct'] == 10 for a in adjustments)

    def test_decline_discount(self):
        adjustments = self.calc.get_standard_adjustments(growth_rate=-0.15)
        assert any(a['pct'] == -15 for a in adjustments)

    def test_no_adjustments_for_average_business(self):
        adjustments = self.calc.get_standard_adjustments(
            owner_dependent=False,
            recurring_revenue_pct=20,
            customer_concentration_pct=10,
            revenue_millions=1,
            growth_rate=0.05,
        )
        assert len(adjustments) == 0


class TestIndustryMultiples:
    """Test industry multiples data."""

    def test_all_industries_have_required_keys(self):
        required_keys = {
            'sde_multiple_low', 'sde_multiple_mid', 'sde_multiple_high',
            'revenue_multiple_low', 'revenue_multiple_mid', 'revenue_multiple_high',
            'median_sale_price',
        }

        for industry, multiples in INDUSTRY_MULTIPLES.items():
            for key in required_keys:
                assert key in multiples, f"Missing {key} for {industry}"

    def test_multiples_ordering(self):
        for industry, m in INDUSTRY_MULTIPLES.items():
            assert m['sde_multiple_low'] <= m['sde_multiple_mid'] <= m['sde_multiple_high'], \
                f"SDE multiples not ordered for {industry}"

    def test_list_industries(self):
        industries = ValuationCalculator.list_industries()
        assert 'hvac' in industries
        assert 'default' not in industries

    def test_get_multiples(self):
        multiples = ValuationCalculator.get_multiples('HVAC')
        assert multiples is not None
        assert multiples['sde_multiple_mid'] == 2.79
