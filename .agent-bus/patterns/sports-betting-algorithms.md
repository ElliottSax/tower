# Sports Betting Algorithms - Extracted Patterns

**Source Project**: Sports Analytics (FROZEN 2026-02-11)
**Extraction Date**: 2026-02-11
**Status**: Reference implementation for future use

---

## Overview

These algorithms were extracted from the frozen Sports Analytics project. They represent the **core domain logic** for sports betting analytics and can be integrated into other financial platforms (e.g., Quant) if the sports betting vertical is pursued.

---

## 1. Arbitrage Detection

**File**: `src/calculators/arbitrage.py`

### Core Concept
Arbitrage exists when you can bet on all possible outcomes of an event and guarantee profit regardless of the result.

### Formula
```
Arbitrage exists when: (1/odds_a) + (1/odds_b) < 1

For two-way markets (win/lose):
  implied_sum = (1 / decimal_odds_a) + (1 / decimal_odds_b)
  is_arbitrage = implied_sum < 1
  profit_margin = (1 - implied_sum) * 100

For three-way markets (win/draw/lose):
  implied_sum = (1/odds_a) + (1/odds_b) + (1/odds_c)
```

### Stake Distribution
```python
# For a total stake of $100 with guaranteed profit:
stake_a = (total_stake / implied_sum) * (1 / odds_a)
stake_b = (total_stake / implied_sum) * (1 / odds_b)

# Guaranteed return is the same regardless of outcome:
return = stake_a * odds_a = stake_b * odds_b
profit = return - total_stake
```

### Implementation Pattern
```python
class ArbitrageCalculator:
    def __init__(
        self,
        min_profit_percent: float = 0.5,  # Minimum 0.5% profit
        max_profit_percent: float = 10.0,  # Sanity check
        min_stake: float = 10.0,
        round_stakes: bool = True
    ):
        self.min_profit_percent = min_profit_percent
        self.max_profit_percent = max_profit_percent
        self.min_stake = min_stake
        self.round_stakes = round_stakes

    @staticmethod
    def american_to_decimal(american_odds: int) -> float:
        """Convert American odds (+150, -110) to decimal (2.50, 1.91)"""
        if american_odds > 0:
            return (american_odds / 100) + 1
        else:
            return (100 / abs(american_odds)) + 1

    @staticmethod
    def implied_probability(decimal_odds: float) -> float:
        """Convert odds to implied probability"""
        return 1 / decimal_odds

    def check_two_way_arbitrage(
        self,
        odds_a: float,
        odds_b: float
    ) -> Tuple[bool, float]:
        """Check if arbitrage exists between two outcomes"""
        implied_sum = (1 / odds_a) + (1 / odds_b)
        is_arb = implied_sum < 1
        profit_pct = (1 - implied_sum) * 100 if is_arb else 0
        return is_arb, profit_pct
```

### Real-World Example
```
Event: Lakers vs Celtics
Bookmaker A offers Lakers at 2.10 (decimal) / +110 (American)
Bookmaker B offers Celtics at 2.05 (decimal) / +105 (American)

Implied sum = (1/2.10) + (1/2.05) = 0.476 + 0.488 = 0.964

Since 0.964 < 1, arbitrage exists!
Profit margin = (1 - 0.964) * 100 = 3.6%

With $1000 total stake:
  Bet on Lakers: $1000 * (1/2.10) / 0.964 = $493.40
  Bet on Celtics: $1000 * (1/2.05) / 0.964 = $506.60

If Lakers win: Return = $493.40 * 2.10 = $1036
If Celtics win: Return = $506.60 * 2.05 = $1038.50
Profit = ~$36-38 guaranteed
```

---

## 2. Kelly Criterion (Optimal Bet Sizing)

**File**: `src/calculators/kelly.py`

### Core Concept
The Kelly Criterion determines the optimal fraction of your bankroll to bet to maximize long-term logarithmic growth.

### Formula
```
f* = (bp - q) / b

Where:
  f* = fraction of bankroll to bet
  b = odds received (decimal_odds - 1)
  p = probability of winning
  q = probability of losing (1 - p)
```

### Fractional Kelly
Full Kelly is aggressive. Most professionals use **1/4 Kelly or 1/2 Kelly** for safety:
```
adjusted_fraction = kelly_fraction * fractional_multiplier
final_stake = min(adjusted_fraction, max_bet_percent) * bankroll
```

### Implementation Pattern
```python
class KellyCalculator:
    def __init__(
        self,
        bankroll: float = 10000.0,
        kelly_fraction: float = 0.25,      # Use 1/4 Kelly (safer)
        max_bet_percent: float = 0.10,     # Never bet >10% of bankroll
        min_edge: float = 0.01,            # Minimum 1% edge required
    ):
        self.bankroll = bankroll
        self.kelly_fraction = kelly_fraction
        self.max_bet_percent = max_bet_percent
        self.min_edge = min_edge

    def calculate_single_bet(
        self,
        odds_decimal: float,
        win_probability: float
    ) -> KellyResult:
        """Calculate optimal Kelly stake"""
        b = odds_decimal - 1  # Net odds
        p = win_probability
        q = 1 - p

        # Kelly formula
        edge = (b * p) - q
        kelly_fraction = edge / b if b > 0 else 0

        # Apply fractional Kelly
        adjusted_fraction = kelly_fraction * self.kelly_fraction

        # Cap at max bet percent
        final_fraction = min(adjusted_fraction, self.max_bet_percent)

        # Don't bet if edge is negative or too small
        if edge < self.min_edge:
            final_fraction = 0

        # Calculate expected growth rate (log utility)
        if final_fraction > 0 and p > 0 and q > 0:
            expected_growth = (
                p * math.log(1 + final_fraction * b) +
                q * math.log(1 - final_fraction)
            )
        else:
            expected_growth = 0

        return KellyResult(
            fraction=max(0, final_fraction),
            stake=final_fraction * self.bankroll,
            expected_growth=expected_growth,
            edge=edge * 100,
            is_positive_ev=edge > 0
        )
```

### Real-World Example
```
Bankroll: $10,000
Odds: 2.5 (decimal) = +150 (American)
True win probability: 50% (you estimate coin flip, but odds imply 40%)

b = 2.5 - 1 = 1.5
p = 0.50
q = 0.50

Full Kelly: f* = (1.5 * 0.50 - 0.50) / 1.5 = (0.75 - 0.50) / 1.5 = 0.167 (16.7%)
1/4 Kelly: 0.167 * 0.25 = 0.042 (4.2%)

Stake = $10,000 * 0.042 = $420
```

---

## 3. Expected Value (EV) Calculator

**File**: `src/calculators/ev.py`

### Core Concept
Expected value determines if a bet is profitable long-term, even without arbitrage.

### Formula
```
EV = (Probability of Win × Profit) - (Probability of Loss × Stake)

For decimal odds d and true probability p:
EV = (p × (d - 1)) - ((1 - p) × 1)
EV = p × d - 1

Edge = true_probability - implied_probability
```

### Implementation Pattern
```python
class EVCalculator:
    def __init__(self, kelly_fraction: float = 0.25):
        self.kelly_fraction = kelly_fraction

    @staticmethod
    def decimal_to_implied_prob(decimal_odds: float) -> float:
        """Convert odds to implied probability"""
        return 1 / decimal_odds

    def calculate_ev(
        self,
        odds_decimal: float,
        true_probability: float
    ) -> Tuple[float, float]:
        """
        Calculate expected value.

        Returns:
            Tuple of (ev_percent, edge_percent)
        """
        # Implied probability from odds
        implied_prob = 1 / odds_decimal

        # Edge = true probability - implied probability
        edge = true_probability - implied_prob

        # EV = true_prob × odds - 1
        ev = (true_probability * odds_decimal) - 1

        return ev * 100, edge * 100  # As percentages

    def find_plus_ev_bets(
        self,
        odds_data: List[Dict],
        true_probabilities: Dict[str, float],
        min_edge: float = 2.0
    ) -> List[EVBet]:
        """Find all +EV opportunities above minimum edge threshold"""
        plus_ev_bets = []

        for data in odds_data:
            outcome = data['outcome']
            true_prob = true_probabilities.get(outcome)

            if not true_prob:
                continue

            ev_pct, edge_pct = self.calculate_ev(
                data['odds_decimal'],
                true_prob
            )

            if edge_pct >= min_edge:
                plus_ev_bets.append(EVBet(
                    event_name=data['event'],
                    outcome=outcome,
                    bookmaker=data['bookmaker'],
                    odds_decimal=data['odds_decimal'],
                    true_probability=true_prob,
                    edge_percent=edge_pct,
                    ev_percent=ev_pct
                ))

        return sorted(plus_ev_bets, key=lambda x: x.edge_percent, reverse=True)
```

### Real-World Example
```
Bet: Lakers to win
Odds: 2.20 (decimal) = +120 (American)
Implied probability: 1 / 2.20 = 45.45%
Your estimate (from model): 52% chance Lakers win

Edge = 52% - 45.45% = 6.55%
EV = (0.52 × 2.20) - 1 = 0.144 = 14.4%

For every $100 bet:
  Expected return = $100 × 1.144 = $114.40
  Expected profit = $14.40 long-term

This is a +EV bet worth taking.
```

---

## 4. Odds Conversion Utilities

### American ↔ Decimal
```python
def american_to_decimal(american: int) -> float:
    """Convert American odds to decimal"""
    if american > 0:  # Underdog (+150)
        return (american / 100) + 1
    else:             # Favorite (-110)
        return (100 / abs(american)) + 1

def decimal_to_american(decimal: float) -> int:
    """Convert decimal odds to American"""
    if decimal >= 2.0:  # Underdog
        return int((decimal - 1) * 100)
    else:               # Favorite
        return int(-100 / (decimal - 1))
```

### Examples
```
+150 (American) → 2.50 (decimal)
-110 (American) → 1.91 (decimal)
2.00 (decimal)  → +100 (American) [even money]
1.50 (decimal)  → -200 (American)
```

---

## 5. Sharp Money Detection

**File**: `src/analytics.py`

### Steam Moves
Rapid line movement indicating sharp (professional) money:
```python
def detect_steam_move(
    initial_odds: float,
    current_odds: float,
    time_elapsed_minutes: int,
    threshold_percent: float = 5.0,
    max_time_window: int = 30
) -> bool:
    """
    Detect if a line movement qualifies as a steam move.

    Steam move criteria:
    - Significant odds shift (>5% typically)
    - Happens quickly (<30 minutes)
    - Indicates sharp money influencing the line
    """
    if time_elapsed_minutes > max_time_window:
        return False

    change_percent = abs(current_odds - initial_odds) / initial_odds * 100
    return change_percent >= threshold_percent
```

### Line Movement Tracking
```python
def track_line_movement(
    event_id: str,
    bookmakers: List[str],
    time_series_data: List[Dict]
) -> Dict:
    """
    Track how odds move across multiple bookmakers.

    Patterns to detect:
    - Reverse line movement (line moves opposite to public betting)
    - Consensus moves (all books move the same direction)
    - Isolated moves (one book adjusts, others don't)
    """
    movements = {
        'consensus': False,
        'reverse': False,
        'sharp_indicator': False,
        'books_moved': []
    }

    # Analyze movement patterns...
    # (Implementation depends on data structure)

    return movements
```

---

## Integration Recommendations

### For Quant Platform Integration

1. **Create New Module**: `/backend/sports/`
   - `arbitrage.py` - Arbitrage detection
   - `kelly.py` - Position sizing
   - `ev.py` - Value bet identification
   - `odds_converters.py` - Utility functions

2. **Data Sources**:
   - The Odds API (theOddsAPI.com) - Real-time odds
   - Sports DataFeeds (sportsdata.io)
   - Free alternatives: ESPN, Yahoo Sports (scraping required)

3. **Revenue Model Addition**:
   - QUANT BASIC: $29/mo - Congressional + options data
   - QUANT PRO: $99/mo - Add sports betting analytics
   - QUANT ELITE: $199/mo - Add real-time arbitrage alerts

4. **Estimated Integration Effort**: 20-30 hours
   - Extract algorithms: 4 hours
   - Integrate with Quant API: 8 hours
   - Add sports data sources: 8 hours
   - UI components: 6 hours
   - Testing: 4 hours

---

## License & Attribution

**Original Author**: Sports Analytics Agent
**Frozen From**: `/mnt/e/projects/sports/`
**Date**: 2026-02-11
**Status**: Reference implementation - adapt as needed

These algorithms are mathematical formulas and standard betting industry calculations. They are not patentable and can be freely implemented. The specific Python implementations were created for the Sports Analytics project but represent well-known industry formulas.

---

## References

- **Kelly Criterion**: J.L. Kelly Jr., "A New Interpretation of Information Rate" (1956)
- **Arbitrage Betting**: Standard bookmaker mathematics
- **Expected Value**: Fundamental probability theory
- **The Odds API**: https://the-odds-api.com/
- **BettingPros**: https://www.bettingpros.com/ (competitor reference)
- **OddsJam**: https://oddsjam.com/ (competitor reference)
