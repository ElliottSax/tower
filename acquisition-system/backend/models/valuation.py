"""
Business valuation calculator with SDE computation and industry multiples.
Implements the valuation methodologies from the acquisition playbook.
"""

from typing import Dict, Optional, List, Tuple
from dataclasses import dataclass, field
from enum import Enum

from ..utils.logging import setup_logging


logger = setup_logging(__name__)


# Industry multiples database (2024-2025 BizBuySell data)
INDUSTRY_MULTIPLES = {
    'hvac': {
        'sde_multiple_low': 2.20, 'sde_multiple_mid': 2.79, 'sde_multiple_high': 3.50,
        'revenue_multiple_low': 0.40, 'revenue_multiple_mid': 0.59, 'revenue_multiple_high': 0.80,
        'median_sale_price': 750_000,
    },
    'plumbing': {
        'sde_multiple_low': 2.00, 'sde_multiple_mid': 2.51, 'sde_multiple_high': 3.20,
        'revenue_multiple_low': 0.45, 'revenue_multiple_mid': 0.67, 'revenue_multiple_high': 0.90,
        'median_sale_price': 649_500,
    },
    'electrical_contracting': {
        'sde_multiple_low': 2.20, 'sde_multiple_mid': 2.72, 'sde_multiple_high': 3.40,
        'revenue_multiple_low': 0.40, 'revenue_multiple_mid': 0.61, 'revenue_multiple_high': 0.85,
        'median_sale_price': 1_000_000,
    },
    'landscaping': {
        'sde_multiple_low': 1.90, 'sde_multiple_mid': 2.46, 'sde_multiple_high': 3.10,
        'revenue_multiple_low': 0.50, 'revenue_multiple_mid': 0.70, 'revenue_multiple_high': 0.95,
        'median_sale_price': 425_000,
    },
    'pest_control': {
        'sde_multiple_low': 1.90, 'sde_multiple_mid': 2.40, 'sde_multiple_high': 3.00,
        'revenue_multiple_low': 0.70, 'revenue_multiple_mid': 0.99, 'revenue_multiple_high': 1.30,
        'median_sale_price': 249_000,
    },
    'insurance_agency': {
        'sde_multiple_low': 2.20, 'sde_multiple_mid': 2.86, 'sde_multiple_high': 3.60,
        'revenue_multiple_low': 1.10, 'revenue_multiple_mid': 1.52, 'revenue_multiple_high': 2.00,
        'median_sale_price': 497_500,
    },
    'accounting_practice': {
        'sde_multiple_low': 1.80, 'sde_multiple_mid': 2.23, 'sde_multiple_high': 2.80,
        'revenue_multiple_low': 0.80, 'revenue_multiple_mid': 1.07, 'revenue_multiple_high': 1.40,
        'median_sale_price': 424_000,
    },
    'restaurant': {
        'sde_multiple_low': 1.50, 'sde_multiple_mid': 2.20, 'sde_multiple_high': 3.00,
        'revenue_multiple_low': 0.25, 'revenue_multiple_mid': 0.40, 'revenue_multiple_high': 0.60,
        'median_sale_price': 250_000,
    },
    'auto_repair': {
        'sde_multiple_low': 1.80, 'sde_multiple_mid': 2.40, 'sde_multiple_high': 3.00,
        'revenue_multiple_low': 0.30, 'revenue_multiple_mid': 0.50, 'revenue_multiple_high': 0.70,
        'median_sale_price': 350_000,
    },
    'manufacturing': {
        'sde_multiple_low': 2.50, 'sde_multiple_mid': 3.50, 'sde_multiple_high': 5.00,
        'revenue_multiple_low': 0.40, 'revenue_multiple_mid': 0.65, 'revenue_multiple_high': 1.00,
        'median_sale_price': 800_000,
    },
    'it_services': {
        'sde_multiple_low': 2.50, 'sde_multiple_mid': 3.20, 'sde_multiple_high': 4.50,
        'revenue_multiple_low': 0.60, 'revenue_multiple_mid': 1.00, 'revenue_multiple_high': 1.50,
        'median_sale_price': 600_000,
    },
    'ecommerce': {
        'sde_multiple_low': 2.50, 'sde_multiple_mid': 3.50, 'sde_multiple_high': 5.00,
        'revenue_multiple_low': 0.60, 'revenue_multiple_mid': 1.00, 'revenue_multiple_high': 1.80,
        'median_sale_price': 400_000,
    },
    'default': {
        'sde_multiple_low': 2.00, 'sde_multiple_mid': 2.70, 'sde_multiple_high': 3.50,
        'revenue_multiple_low': 0.40, 'revenue_multiple_mid': 0.65, 'revenue_multiple_high': 1.00,
        'median_sale_price': 500_000,
    },
}


@dataclass
class SDEAddBack:
    """Individual SDE add-back item."""
    category: str
    description: str
    amount: float
    is_standard: bool = True  # Standard add-backs vs. discretionary


@dataclass
class SDECalculation:
    """Result of SDE calculation."""
    net_income: float
    add_backs: List[SDEAddBack]
    total_add_backs: float
    sde: float
    normalized_owner_salary: Optional[float] = None
    owner_salary_adjustment: float = 0


@dataclass
class ValuationResult:
    """Complete business valuation result."""
    business_name: str
    industry: str

    # SDE
    sde_calculation: SDECalculation

    # Valuation range
    valuation_low: float
    valuation_mid: float
    valuation_high: float

    # Multiples used
    sde_multiple_low: float
    sde_multiple_mid: float
    sde_multiple_high: float

    # Revenue-based cross-check
    revenue: Optional[float] = None
    revenue_valuation_low: Optional[float] = None
    revenue_valuation_mid: Optional[float] = None
    revenue_valuation_high: Optional[float] = None

    # Adjustments
    adjustments: List[Dict] = field(default_factory=list)
    total_adjustment_pct: float = 0.0

    # Deal structure suggestion
    suggested_structure: Optional[Dict] = None

    def to_dict(self) -> Dict:
        return {
            'business_name': self.business_name,
            'industry': self.industry,
            'sde': self.sde_calculation.sde,
            'valuation_low': self.valuation_low,
            'valuation_mid': self.valuation_mid,
            'valuation_high': self.valuation_high,
            'multiples': {
                'low': self.sde_multiple_low,
                'mid': self.sde_multiple_mid,
                'high': self.sde_multiple_high,
            },
            'adjustments': self.adjustments,
            'suggested_structure': self.suggested_structure,
        }


class ValuationCalculator:
    """
    Business valuation calculator.

    Implements:
    - SDE calculation with standard add-backs
    - Industry-specific multiples
    - Size, risk, and quality adjustments
    - Deal structure suggestions
    """

    def calculate_sde(
        self,
        net_income: float,
        owner_salary: float = 0,
        owner_benefits: float = 0,
        interest: float = 0,
        depreciation: float = 0,
        amortization: float = 0,
        owner_perks: Optional[Dict[str, float]] = None,
        one_time_expenses: Optional[Dict[str, float]] = None,
        market_rate_salary: Optional[float] = None,
    ) -> SDECalculation:
        """
        Calculate Seller's Discretionary Earnings.

        SDE = Net Income + Owner Salary + Owner Benefits + Interest +
              Depreciation + Amortization + Discretionary Expenses + Non-Recurring

        Args:
            net_income: Reported net income
            owner_salary: Owner's total compensation
            owner_benefits: Health/life insurance, 401k, etc.
            interest: Interest expense
            depreciation: Depreciation expense
            amortization: Amortization expense
            owner_perks: Dict of discretionary expenses (vehicle, cell, travel, etc.)
            one_time_expenses: Dict of non-recurring expenses
            market_rate_salary: Fair market salary for owner's role

        Returns:
            SDECalculation with full breakdown
        """
        add_backs = []

        # Standard add-backs
        if owner_salary > 0:
            add_backs.append(SDEAddBack("Owner Compensation", "Owner salary and bonuses", owner_salary))

        if owner_benefits > 0:
            add_backs.append(SDEAddBack("Owner Benefits", "Health, life, disability, 401k", owner_benefits))

        if interest > 0:
            add_backs.append(SDEAddBack("Interest", "Interest expense", interest))

        if depreciation > 0:
            add_backs.append(SDEAddBack("Depreciation", "Depreciation expense", depreciation))

        if amortization > 0:
            add_backs.append(SDEAddBack("Amortization", "Amortization expense", amortization))

        # Discretionary/perks add-backs
        if owner_perks:
            for name, amount in owner_perks.items():
                add_backs.append(SDEAddBack(
                    f"Owner Perk: {name}",
                    f"Discretionary: {name}",
                    amount,
                    is_standard=False
                ))

        # One-time expenses
        if one_time_expenses:
            for name, amount in one_time_expenses.items():
                add_backs.append(SDEAddBack(
                    f"Non-Recurring: {name}",
                    f"One-time expense: {name}",
                    amount,
                    is_standard=False
                ))

        total_add_backs = sum(ab.amount for ab in add_backs)
        sde = net_income + total_add_backs

        # Normalize owner salary to market rate
        owner_salary_adjustment = 0.0
        if market_rate_salary and owner_salary:
            # If owner takes more than market rate, add back the excess
            # If owner takes less, we need to subtract the shortfall
            owner_salary_adjustment = owner_salary - market_rate_salary

        return SDECalculation(
            net_income=net_income,
            add_backs=add_backs,
            total_add_backs=total_add_backs,
            sde=sde,
            normalized_owner_salary=market_rate_salary,
            owner_salary_adjustment=owner_salary_adjustment,
        )

    def valuate(
        self,
        business_name: str,
        industry: str,
        sde: float,
        revenue: Optional[float] = None,
        adjustments: Optional[List[Dict]] = None,
    ) -> ValuationResult:
        """
        Calculate business valuation.

        Args:
            business_name: Name of business
            industry: Industry key (from INDUSTRY_MULTIPLES)
            sde: Seller's Discretionary Earnings
            revenue: Annual revenue (for cross-check)
            adjustments: List of {name, pct} adjustments to apply

        Returns:
            ValuationResult with full analysis
        """
        # Get industry multiples
        industry_key = industry.lower().replace(' ', '_').replace('-', '_')
        multiples = INDUSTRY_MULTIPLES.get(industry_key, INDUSTRY_MULTIPLES['default'])

        # Base valuation range
        valuation_low = sde * multiples['sde_multiple_low']
        valuation_mid = sde * multiples['sde_multiple_mid']
        valuation_high = sde * multiples['sde_multiple_high']

        # Apply adjustments
        all_adjustments = adjustments or []
        total_adjustment = sum(a['pct'] for a in all_adjustments) / 100.0

        if total_adjustment != 0:
            valuation_low *= (1 + total_adjustment)
            valuation_mid *= (1 + total_adjustment)
            valuation_high *= (1 + total_adjustment)

        # Revenue-based cross-check
        rev_low = rev_mid = rev_high = None
        if revenue:
            rev_low = revenue * multiples['revenue_multiple_low']
            rev_mid = revenue * multiples['revenue_multiple_mid']
            rev_high = revenue * multiples['revenue_multiple_high']

        # Generate deal structure suggestion
        structure = self._suggest_deal_structure(valuation_mid)

        result = ValuationResult(
            business_name=business_name,
            industry=industry,
            sde_calculation=SDECalculation(
                net_income=0, add_backs=[], total_add_backs=0, sde=sde
            ),
            valuation_low=round(valuation_low, -3),
            valuation_mid=round(valuation_mid, -3),
            valuation_high=round(valuation_high, -3),
            sde_multiple_low=multiples['sde_multiple_low'],
            sde_multiple_mid=multiples['sde_multiple_mid'],
            sde_multiple_high=multiples['sde_multiple_high'],
            revenue=revenue,
            revenue_valuation_low=round(rev_low, -3) if rev_low else None,
            revenue_valuation_mid=round(rev_mid, -3) if rev_mid else None,
            revenue_valuation_high=round(rev_high, -3) if rev_high else None,
            adjustments=all_adjustments,
            total_adjustment_pct=total_adjustment * 100,
            suggested_structure=structure,
        )

        return result

    def get_standard_adjustments(
        self,
        owner_dependent: bool = False,
        recurring_revenue_pct: float = 0,
        customer_concentration_pct: float = 0,
        revenue_millions: float = 0,
        growth_rate: float = 0,
    ) -> List[Dict]:
        """
        Calculate standard valuation adjustments.

        Args:
            owner_dependent: High owner dependency (reduces value 10-25%)
            recurring_revenue_pct: Percentage of recurring revenue (increases value)
            customer_concentration_pct: Revenue from top customer (risk factor)
            revenue_millions: Revenue in millions (size premium)
            growth_rate: Year-over-year revenue growth rate

        Returns:
            List of adjustment dicts with name and percentage
        """
        adjustments = []

        # Owner dependency discount
        if owner_dependent:
            adjustments.append({
                'name': 'Owner Dependency Discount',
                'pct': -15,
                'reason': 'Business heavily reliant on owner involvement'
            })

        # Recurring revenue premium
        if recurring_revenue_pct >= 70:
            adjustments.append({
                'name': 'Recurring Revenue Premium',
                'pct': 20,
                'reason': f'{recurring_revenue_pct}% recurring revenue (strong predictability)'
            })
        elif recurring_revenue_pct >= 40:
            adjustments.append({
                'name': 'Recurring Revenue Premium',
                'pct': 10,
                'reason': f'{recurring_revenue_pct}% recurring revenue'
            })

        # Customer concentration risk
        if customer_concentration_pct >= 30:
            adjustments.append({
                'name': 'Customer Concentration Discount',
                'pct': -15,
                'reason': f'Top customer = {customer_concentration_pct}% of revenue'
            })
        elif customer_concentration_pct >= 20:
            adjustments.append({
                'name': 'Customer Concentration Discount',
                'pct': -8,
                'reason': f'Top customer = {customer_concentration_pct}% of revenue'
            })

        # Size premium
        if revenue_millions >= 5:
            adjustments.append({
                'name': 'Size Premium',
                'pct': 15,
                'reason': f'Revenue ≥ $5M commands higher multiples'
            })
        elif revenue_millions >= 2:
            adjustments.append({
                'name': 'Size Premium',
                'pct': 8,
                'reason': f'Revenue ≥ $2M'
            })

        # Growth premium/discount
        if growth_rate >= 0.15:
            adjustments.append({
                'name': 'Growth Premium',
                'pct': 10,
                'reason': f'{growth_rate*100:.0f}% YoY growth'
            })
        elif growth_rate <= -0.10:
            adjustments.append({
                'name': 'Declining Revenue Discount',
                'pct': -15,
                'reason': f'{growth_rate*100:.0f}% YoY revenue decline'
            })

        return adjustments

    def _suggest_deal_structure(self, purchase_price: float) -> Dict:
        """Suggest deal structure based on purchase price."""
        if purchase_price <= 350_000:
            # Small deal - more seller financing
            return {
                'buyer_equity': round(purchase_price * 0.10),
                'buyer_equity_pct': 10,
                'sba_loan': round(purchase_price * 0.75),
                'sba_loan_pct': 75,
                'seller_note': round(purchase_price * 0.15),
                'seller_note_pct': 15,
                'seller_note_rate': '7-9%',
                'seller_note_term': '5-7 years',
                'notes': 'SBA 7(a) loan preferred. Seller note on full standby per SBA rules.'
            }
        elif purchase_price <= 2_000_000:
            # Mid-size deal
            return {
                'buyer_equity': round(purchase_price * 0.10),
                'buyer_equity_pct': 10,
                'sba_loan': round(purchase_price * 0.70),
                'sba_loan_pct': 70,
                'seller_note': round(purchase_price * 0.15),
                'seller_note_pct': 15,
                'earnout': round(purchase_price * 0.05),
                'earnout_pct': 5,
                'seller_note_rate': '7-8%',
                'seller_note_term': '5-7 years',
                'notes': 'SBA 7(a) up to $5M. Seller note on full standby. Small earnout bridges valuation gap.'
            }
        else:
            # Larger deal
            return {
                'buyer_equity': round(purchase_price * 0.15),
                'buyer_equity_pct': 15,
                'senior_debt': round(purchase_price * 0.55),
                'senior_debt_pct': 55,
                'seller_note': round(purchase_price * 0.20),
                'seller_note_pct': 20,
                'earnout': round(purchase_price * 0.10),
                'earnout_pct': 10,
                'seller_note_rate': '6-8%',
                'seller_note_term': '5-7 years',
                'notes': 'May need conventional financing above SBA limits. Equity rollover option worth exploring.'
            }

    @staticmethod
    def list_industries() -> List[str]:
        """List all available industry categories."""
        return [k for k in INDUSTRY_MULTIPLES.keys() if k != 'default']

    @staticmethod
    def get_multiples(industry: str) -> Optional[Dict]:
        """Get multiples for a specific industry."""
        key = industry.lower().replace(' ', '_').replace('-', '_')
        return INDUSTRY_MULTIPLES.get(key)


# Example usage
if __name__ == "__main__":
    calc = ValuationCalculator()

    # Step 1: Calculate SDE
    sde_calc = calc.calculate_sde(
        net_income=150_000,
        owner_salary=120_000,
        owner_benefits=25_000,
        interest=15_000,
        depreciation=30_000,
        amortization=5_000,
        owner_perks={
            'Vehicle': 8_000,
            'Cell Phone': 1_200,
            'Personal Travel': 5_000,
        },
        one_time_expenses={
            'Lawsuit Settlement': 20_000,
        },
        market_rate_salary=100_000,
    )

    print(f"SDE Calculation:")
    print(f"  Net Income:      ${sde_calc.net_income:>12,.0f}")
    print(f"  Add-backs:")
    for ab in sde_calc.add_backs:
        print(f"    + {ab.category:30s} ${ab.amount:>10,.0f}")
    print(f"  {'─' * 46}")
    print(f"  Total SDE:       ${sde_calc.sde:>12,.0f}")

    # Step 2: Get adjustments
    adjustments = calc.get_standard_adjustments(
        owner_dependent=True,
        recurring_revenue_pct=60,
        customer_concentration_pct=15,
        revenue_millions=2.5,
        growth_rate=0.05,
    )

    # Step 3: Valuate
    result = calc.valuate(
        business_name="Smith HVAC Services",
        industry="hvac",
        sde=sde_calc.sde,
        revenue=2_500_000,
        adjustments=adjustments,
    )

    print(f"\nValuation: {result.business_name}")
    print(f"  SDE:                ${result.sde_calculation.sde:>12,.0f}")
    print(f"  Multiple Range:     {result.sde_multiple_low:.2f}x - {result.sde_multiple_high:.2f}x")
    print(f"\n  SDE Valuation:")
    print(f"    Low:              ${result.valuation_low:>12,.0f}")
    print(f"    Mid:              ${result.valuation_mid:>12,.0f}")
    print(f"    High:             ${result.valuation_high:>12,.0f}")

    if result.revenue:
        print(f"\n  Revenue Cross-Check:")
        print(f"    Low:              ${result.revenue_valuation_low:>12,.0f}")
        print(f"    Mid:              ${result.revenue_valuation_mid:>12,.0f}")
        print(f"    High:             ${result.revenue_valuation_high:>12,.0f}")

    if result.adjustments:
        print(f"\n  Adjustments:")
        for adj in result.adjustments:
            sign = '+' if adj['pct'] > 0 else ''
            print(f"    {sign}{adj['pct']}% {adj['name']}: {adj['reason']}")

    if result.suggested_structure:
        print(f"\n  Suggested Deal Structure:")
        for key, value in result.suggested_structure.items():
            if not key.endswith('_pct') and key != 'notes':
                print(f"    {key:20s}: {value}")
        print(f"    Notes: {result.suggested_structure.get('notes', '')}")
