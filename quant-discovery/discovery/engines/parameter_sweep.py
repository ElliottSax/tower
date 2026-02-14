"""Parameter sweep engine - systematically tests parameter combinations."""

import logging
from typing import Dict, List, Any
from itertools import product
import pandas as pd
import numpy as np

logger = logging.getLogger(__name__)


class ParameterSweepEngine:
    """
    Systematically sweep through parameter combinations to find optimal settings.

    This engine takes a model/algorithm and tests all combinations of parameters
    to discover which configurations produce the strongest patterns.
    """

    def __init__(self):
        self.results = []

    def sweep_fourier_parameters(
        self,
        trade_frequency: pd.Series,
        politician_name: str
    ) -> Dict[str, Any]:
        """
        Sweep Fourier analysis parameters.

        Args:
            trade_frequency: Time series of trade frequency
            politician_name: Name of politician (for logging)

        Returns:
            Best parameters and all results
        """
        from discovery.ml.cyclical import FourierCyclicalDetector

        # Parameter grid
        min_strengths = [0.05, 0.10, 0.15, 0.20]
        min_confidences = [0.5, 0.6, 0.7, 0.8, 0.9]

        results = []

        logger.info(f"Sweeping Fourier parameters for {politician_name}")

        for strength, confidence in product(min_strengths, min_confidences):
            try:
                detector = FourierCyclicalDetector(
                    min_strength=strength,
                    min_confidence=confidence
                )

                result = detector.detect_cycles(
                    trade_frequency,
                    sampling_rate='daily',
                    return_details=True
                )

                # Evaluate quality
                quality_score = self._evaluate_fourier_quality(result)

                results.append({
                    'params': {
                        'min_strength': strength,
                        'min_confidence': confidence
                    },
                    'cycles_found': len(result.get('dominant_cycles', [])),
                    'top_cycle_strength': result['dominant_cycles'][0]['strength'] if result.get('dominant_cycles') else 0,
                    'quality_score': quality_score,
                    'result': result
                })

            except Exception as e:
                logger.warning(f"Fourier failed with strength={strength}, confidence={confidence}: {e}")
                continue

        if not results:
            return {'status': 'failed', 'error': 'No valid parameter combinations'}

        # Find best
        best = max(results, key=lambda r: r['quality_score'])

        return {
            'politician_name': politician_name,
            'best_params': best['params'],
            'best_quality_score': best['quality_score'],
            'best_result': best['result'],
            'all_results': results,
            'total_combinations_tested': len(results)
        }

    def sweep_hmm_parameters(
        self,
        returns: pd.Series,
        politician_name: str
    ) -> Dict[str, Any]:
        """
        Sweep HMM regime detection parameters.

        Args:
            returns: Time series of returns
            politician_name: Name of politician

        Returns:
            Best parameters and results
        """
        from discovery.ml.cyclical import RegimeDetector

        # Parameter grid
        n_states_options = [2, 3, 4, 5]
        covariance_types = ['full', 'diag', 'spherical']

        results = []

        logger.info(f"Sweeping HMM parameters for {politician_name}")

        for n_states in n_states_options:
            for cov_type in covariance_types:
                try:
                    detector = RegimeDetector(
                        n_states=n_states,
                        covariance_type=cov_type
                    )

                    result = detector.fit_and_predict(returns)

                    # Evaluate quality (BIC, AIC, etc.)
                    quality_score = self._evaluate_hmm_quality(result, detector)

                    results.append({
                        'params': {
                            'n_states': n_states,
                            'covariance_type': cov_type
                        },
                        'quality_score': quality_score,
                        'bic': result.get('bic'),
                        'aic': result.get('aic'),
                        'result': result
                    })

                except Exception as e:
                    logger.warning(f"HMM failed with n_states={n_states}, cov_type={cov_type}: {e}")
                    continue

        if not results:
            return {'status': 'failed', 'error': 'No valid parameter combinations'}

        best = max(results, key=lambda r: r['quality_score'])

        return {
            'politician_name': politician_name,
            'best_params': best['params'],
            'best_quality_score': best['quality_score'],
            'best_result': best['result'],
            'all_results': results,
            'total_combinations_tested': len(results)
        }

    def sweep_dtw_parameters(
        self,
        trade_frequency: pd.Series,
        politician_name: str
    ) -> Dict[str, Any]:
        """
        Sweep DTW pattern matching parameters.

        Args:
            trade_frequency: Time series data
            politician_name: Name of politician

        Returns:
            Best parameters and results
        """
        from discovery.ml.cyclical import DynamicTimeWarpingMatcher

        # Parameter grid
        window_sizes = [7, 14, 30, 60, 90]
        thresholds = [0.6, 0.7, 0.8, 0.9]

        results = []

        logger.info(f"Sweeping DTW parameters for {politician_name}")

        for window, threshold in product(window_sizes, thresholds):
            try:
                matcher = DynamicTimeWarpingMatcher(similarity_threshold=threshold)

                matches = matcher.find_similar_patterns(
                    current_pattern=trade_frequency,
                    historical_data=trade_frequency,
                    window_size=window,
                    top_k=5
                )

                # Evaluate quality
                quality_score = self._evaluate_dtw_quality(matches)

                results.append({
                    'params': {
                        'window_size': window,
                        'similarity_threshold': threshold
                    },
                    'matches_found': len(matches),
                    'avg_similarity': np.mean([m['similarity_score'] for m in matches]) if matches else 0,
                    'quality_score': quality_score,
                    'matches': matches
                })

            except Exception as e:
                logger.warning(f"DTW failed with window={window}, threshold={threshold}: {e}")
                continue

        if not results:
            return {'status': 'failed', 'error': 'No valid parameter combinations'}

        best = max(results, key=lambda r: r['quality_score'])

        return {
            'politician_name': politician_name,
            'best_params': best['params'],
            'best_quality_score': best['quality_score'],
            'matches': best['matches'],
            'all_results': results,
            'total_combinations_tested': len(results)
        }

    def _evaluate_fourier_quality(self, result: Dict) -> float:
        """Evaluate quality of Fourier results."""
        if not result.get('dominant_cycles'):
            return 0.0

        top_cycle = result['dominant_cycles'][0]

        # Quality = strength × confidence × (cycles found / 10)
        quality = (
            top_cycle['strength'] * 0.5 +
            top_cycle['confidence'] * 0.3 +
            min(len(result['dominant_cycles']) / 10, 1.0) * 0.2
        )

        return quality

    def _evaluate_hmm_quality(self, result: Dict, detector) -> float:
        """Evaluate quality of HMM results using information criteria."""
        # Lower BIC/AIC is better, but we want higher score
        # Normalize by converting to quality score

        bic = result.get('bic', float('inf'))
        aic = result.get('aic', float('inf'))

        if bic == float('inf'):
            return 0.0

        # Simple normalization (lower is better)
        quality = 1.0 / (1.0 + abs(bic) / 1000)

        return quality

    def _evaluate_dtw_quality(self, matches: List[Dict]) -> float:
        """Evaluate quality of DTW matches."""
        if not matches:
            return 0.0

        # Quality = number of matches × avg similarity
        avg_similarity = np.mean([m['similarity_score'] for m in matches])
        quality = min(len(matches) / 10, 1.0) * 0.5 + avg_similarity * 0.5

        return quality
