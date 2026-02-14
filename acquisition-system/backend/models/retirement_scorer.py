"""
Machine learning model for predicting retirement likelihood.
Uses XGBoost gradient boosting classifier.
"""

from typing import Dict, List, Tuple, Optional
from datetime import datetime, date
from pathlib import Path
import pickle
import json

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, roc_auc_score, roc_curve
import xgboost as xgb
from imblearn.over_sampling import SMOTE

from ..utils.config import settings
from ..utils.logging import setup_logging


logger = setup_logging(__name__)


class RetirementScorer:
    """
    Retirement likelihood scoring model.

    Predicts probability (0-1) that a business owner will sell within 24 months.
    """

    def __init__(self, model_path: Optional[Path] = None):
        """
        Initialize scorer.

        Args:
            model_path: Path to saved model (loads if exists)
        """
        self.model = None
        self.feature_names = []
        self.model_version = "1.0"
        self.trained_at = None

        if model_path and model_path.exists():
            self.load_model(model_path)

    def extract_features(self, business_data: Dict) -> Dict[str, float]:
        """
        Extract features from business data.

        Args:
            business_data: Dict with business information

        Returns:
            Dict of feature name -> value
        """
        features = {}

        # === HIGH-VALUE SIGNALS ===

        # Owner age (strongest predictor)
        owner_age = business_data.get('owner_age', 0)
        features['owner_age'] = owner_age
        features['owner_age_55_plus'] = 1 if owner_age >= 55 else 0
        features['owner_age_65_plus'] = 1 if owner_age >= 65 else 0
        features['owner_age_75_plus'] = 1 if owner_age >= 75 else 0

        # Business tenure (formation date)
        incorporation_date = business_data.get('incorporation_date')
        if incorporation_date:
            if isinstance(incorporation_date, str):
                incorporation_date = datetime.fromisoformat(incorporation_date).date()

            years_in_business = (date.today() - incorporation_date).days / 365.25
            features['years_in_business'] = years_in_business
            features['business_tenure_15_plus'] = 1 if years_in_business >= 15 else 0
            features['business_tenure_20_plus'] = 1 if years_in_business >= 20 else 0
        else:
            features['years_in_business'] = 0
            features['business_tenure_15_plus'] = 0
            features['business_tenure_20_plus'] = 0

        # Marketplace listing (strongest direct signal)
        features['active_marketplace_listing'] = 1 if business_data.get('bizbuysell_listing') else 0

        # PE hold period (for PE-owned businesses)
        pe_acquisition_date = business_data.get('pe_acquisition_date')
        if pe_acquisition_date:
            if isinstance(pe_acquisition_date, str):
                pe_acquisition_date = datetime.fromisoformat(pe_acquisition_date).date()

            years_since_pe_acquisition = (date.today() - pe_acquisition_date).days / 365.25
            features['pe_hold_period_years'] = years_since_pe_acquisition
            features['pe_hold_period_5_plus'] = 1 if years_since_pe_acquisition >= 5 else 0
        else:
            features['pe_hold_period_years'] = 0
            features['pe_hold_period_5_plus'] = 0

        # === MEDIUM-VALUE SIGNALS ===

        # Digital presence decay
        website_last_updated = business_data.get('website_last_updated')
        if website_last_updated:
            if isinstance(website_last_updated, str):
                website_last_updated = datetime.fromisoformat(website_last_updated).date()

            days_since_update = (date.today() - website_last_updated).days
            features['days_since_website_update'] = days_since_update
            features['website_outdated'] = 1 if days_since_update > 365 else 0
        else:
            features['days_since_website_update'] = 0
            features['website_outdated'] = 0

        features['website_ssl_invalid'] = 1 if not business_data.get('website_ssl_valid', True) else 0

        # Social media activity
        linkedin_last_post_days = business_data.get('linkedin_last_post_days', 0)
        features['linkedin_last_post_days'] = linkedin_last_post_days
        features['linkedin_inactive'] = 1 if linkedin_last_post_days > 90 else 0

        # Review velocity decline
        google_reviews_last_90_days = business_data.get('google_reviews_last_90_days', 0)
        google_reviews_previous_90_days = business_data.get('google_reviews_previous_90_days', 0)

        if google_reviews_previous_90_days > 0:
            review_velocity_decline = (google_reviews_previous_90_days - google_reviews_last_90_days) / google_reviews_previous_90_days
        else:
            review_velocity_decline = 0

        features['review_velocity_decline'] = max(0, review_velocity_decline)

        # Headcount decline
        current_employees = business_data.get('current_employees', 0)
        employees_1_year_ago = business_data.get('employees_1_year_ago', current_employees)

        if employees_1_year_ago > 0:
            headcount_decline_pct = (employees_1_year_ago - current_employees) / employees_1_year_ago
        else:
            headcount_decline_pct = 0

        features['headcount_decline_pct'] = max(0, headcount_decline_pct)
        features['headcount_decline'] = 1 if headcount_decline_pct > 0.1 else 0

        # Succession planning
        features['no_succession_plan'] = 1 if not business_data.get('has_succession_plan', False) else 0
        features['multiple_owners'] = 1 if business_data.get('owner_count', 1) > 1 else 0

        # === BUSINESS CHARACTERISTICS ===

        # Size (larger businesses score higher)
        revenue = business_data.get('estimated_revenue', 0)
        features['revenue_millions'] = revenue / 1_000_000 if revenue else 0
        features['revenue_under_1m'] = 1 if revenue < 1_000_000 else 0
        features['revenue_1m_to_5m'] = 1 if 1_000_000 <= revenue < 5_000_000 else 0
        features['revenue_5m_plus'] = 1 if revenue >= 5_000_000 else 0

        # Industry risk factors (certain industries have higher exit rates)
        industry = business_data.get('industry', '').lower()
        high_exit_industries = ['restaurant', 'retail', 'construction', 'manufacturing']
        features['high_exit_industry'] = 1 if any(ind in industry for ind in high_exit_industries) else 0

        # Entity type (C-Corps easier to sell)
        entity_type = business_data.get('entity_type', '').upper()
        features['entity_c_corp'] = 1 if 'CORPORATION' in entity_type or 'INC' in entity_type else 0
        features['entity_llc'] = 1 if 'LLC' in entity_type else 0

        return features

    def calculate_score(self, features: Dict[str, float]) -> Tuple[float, Dict[str, float]]:
        """
        Calculate retirement likelihood score.

        Args:
            features: Feature dictionary from extract_features()

        Returns:
            Tuple of (composite_score, individual_signals)
        """
        if self.model:
            # Use trained ML model
            X = pd.DataFrame([features])
            X = X[self.feature_names]  # Ensure correct order
            score = self.model.predict_proba(X)[0][1]  # Probability of class 1 (will sell)

        else:
            # Use rule-based scoring with configured weights
            weights = settings.get_feature_weights()

            # Calculate individual signal scores (0-1)
            signals = {
                'marketplace_listing': features.get('active_marketplace_listing', 0),

                'owner_age': min(1.0, (
                    0.5 * features.get('owner_age_55_plus', 0) +
                    0.8 * features.get('owner_age_65_plus', 0) +
                    1.0 * features.get('owner_age_75_plus', 0)
                )),

                'business_tenure': min(1.0, (
                    0.6 * features.get('business_tenure_15_plus', 0) +
                    0.9 * features.get('business_tenure_20_plus', 0)
                )),

                'pe_hold_period': features.get('pe_hold_period_5_plus', 0),

                'digital_decay': min(1.0, (
                    0.3 * features.get('website_outdated', 0) +
                    0.2 * features.get('website_ssl_invalid', 0) +
                    0.3 * features.get('linkedin_inactive', 0) +
                    0.2 * features.get('review_velocity_decline', 0)
                )),

                'headcount_decline': features.get('headcount_decline', 0),

                'no_succession_plan': features.get('no_succession_plan', 0)
            }

            # Weighted composite score
            score = sum(signals[key] * weights[key] for key in signals.keys())

        # Cap at 1.0
        score = min(1.0, score)

        # Calculate individual signals for reporting
        signals = self._calculate_individual_signals(features)

        return score, signals

    def _calculate_individual_signals(self, features: Dict[str, float]) -> Dict[str, float]:
        """Calculate individual signal scores for transparency."""
        return {
            'marketplace_listing': features.get('active_marketplace_listing', 0),
            'owner_age': min(1.0, features.get('owner_age', 0) / 75.0),  # Normalize to 0-1
            'business_tenure': min(1.0, features.get('years_in_business', 0) / 25.0),
            'pe_hold_period': min(1.0, features.get('pe_hold_period_years', 0) / 7.0),
            'digital_decay': min(1.0, (
                features.get('website_outdated', 0) * 0.4 +
                features.get('linkedin_inactive', 0) * 0.6
            )),
            'headcount_decline': features.get('headcount_decline_pct', 0),
            'no_succession_plan': features.get('no_succession_plan', 0)
        }

    def train(
        self,
        training_data: pd.DataFrame,
        target_column: str = 'sold_within_24_months',
        test_size: float = 0.2,
        balance_classes: bool = True
    ) -> Dict:
        """
        Train the scoring model.

        Args:
            training_data: DataFrame with features and target
            target_column: Name of target column (1 = sold, 0 = not sold)
            test_size: Fraction of data for testing
            balance_classes: Use SMOTE to balance classes

        Returns:
            Dict with training metrics
        """
        logger.info(f"Training model on {len(training_data)} records")

        # Separate features and target
        y = training_data[target_column]
        X = training_data.drop(columns=[target_column])

        # Store feature names
        self.feature_names = list(X.columns)

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )

        # Balance classes if needed (retirement sales are rare events)
        if balance_classes:
            smote = SMOTE(random_state=42)
            X_train, y_train = smote.fit_resample(X_train, y_train)
            logger.info(f"After SMOTE: {len(X_train)} training samples")

        # Train XGBoost model
        self.model = xgb.XGBClassifier(
            objective='binary:logistic',
            eval_metric='auc',
            max_depth=5,
            learning_rate=0.1,
            n_estimators=100,
            subsample=0.8,
            colsample_bytree=0.8,
            random_state=42
        )

        self.model.fit(
            X_train, y_train,
            eval_set=[(X_test, y_test)],
            verbose=False
        )

        # Evaluate
        y_pred = self.model.predict(X_test)
        y_pred_proba = self.model.predict_proba(X_test)[:, 1]

        auc = roc_auc_score(y_test, y_pred_proba)
        logger.info(f"Model AUC: {auc:.4f}")

        # Cross-validation
        cv_scores = cross_val_score(self.model, X, y, cv=5, scoring='roc_auc')
        logger.info(f"Cross-validation AUC: {cv_scores.mean():.4f} (+/- {cv_scores.std():.4f})")

        # Feature importance
        feature_importance = pd.DataFrame({
            'feature': self.feature_names,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)

        logger.info("Top 10 features:")
        logger.info(f"\n{feature_importance.head(10)}")

        self.trained_at = datetime.now()

        metrics = {
            'auc': auc,
            'cv_auc_mean': cv_scores.mean(),
            'cv_auc_std': cv_scores.std(),
            'classification_report': classification_report(y_test, y_pred),
            'feature_importance': feature_importance.to_dict('records'),
            'trained_at': self.trained_at.isoformat()
        }

        return metrics

    def save_model(self, path: Path):
        """Save model to disk."""
        path.parent.mkdir(parents=True, exist_ok=True)

        model_data = {
            'model': self.model,
            'feature_names': self.feature_names,
            'model_version': self.model_version,
            'trained_at': self.trained_at.isoformat() if self.trained_at else None
        }

        with open(path, 'wb') as f:
            pickle.dump(model_data, f)

        logger.info(f"Model saved to {path}")

    def load_model(self, path: Path):
        """Load model from disk."""
        with open(path, 'rb') as f:
            model_data = pickle.load(f)

        self.model = model_data['model']
        self.feature_names = model_data['feature_names']
        self.model_version = model_data.get('model_version', '1.0')
        self.trained_at = datetime.fromisoformat(model_data['trained_at']) if model_data.get('trained_at') else None

        logger.info(f"Model loaded from {path} (version {self.model_version})")


# Example usage
if __name__ == "__main__":
    scorer = RetirementScorer()

    # Example business
    business = {
        'owner_age': 67,
        'incorporation_date': '2005-03-15',
        'bizbuysell_listing': False,
        'website_last_updated': '2023-01-01',
        'website_ssl_valid': True,
        'estimated_revenue': 2_500_000,
        'current_employees': 15,
        'employees_1_year_ago': 18,
        'industry': 'HVAC',
        'entity_type': 'LLC',
        'has_succession_plan': False
    }

    features = scorer.extract_features(business)
    score, signals = scorer.calculate_score(features)

    print(f"Retirement Likelihood Score: {score:.4f}")
    print("\nIndividual Signals:")
    for signal, value in signals.items():
        print(f"  {signal}: {value:.2f}")

    # Classify
    if score >= 0.70:
        tier = "HOT"
    elif score >= 0.45:
        tier = "WARM"
    else:
        tier = "COLD"

    print(f"\nTier: {tier}")
