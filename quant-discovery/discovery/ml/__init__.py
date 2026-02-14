"""ML algorithms for pattern detection."""

from discovery.ml.cyclical import (
    FourierCyclicalDetector,
    RegimeDetector,
    DynamicTimeWarpingMatcher,
)
from discovery.ml.ensemble import EnsemblePredictor
from discovery.ml.correlation import CorrelationAnalyzer
from discovery.ml.insights import InsightGenerator

__all__ = [
    "FourierCyclicalDetector",
    "RegimeDetector",
    "DynamicTimeWarpingMatcher",
    "EnsemblePredictor",
    "CorrelationAnalyzer",
    "InsightGenerator",
]
