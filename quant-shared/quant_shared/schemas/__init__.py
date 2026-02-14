"""Shared Pydantic schemas for API serialization."""

from typing import Optional
from datetime import date, datetime
from decimal import Decimal
import uuid

from pydantic import BaseModel, Field


class PoliticianBase(BaseModel):
    """Base politician schema."""
    name: str
    chamber: str
    party: Optional[str] = None
    state: Optional[str] = None
    bioguide_id: Optional[str] = None


class PoliticianCreate(PoliticianBase):
    """Schema for creating a politician."""
    pass


class PoliticianResponse(PoliticianBase):
    """Schema for politician response."""
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class TradeBase(BaseModel):
    """Base trade schema."""
    politician_id: uuid.UUID
    ticker: str
    transaction_type: str
    amount_min: Optional[Decimal] = None
    amount_max: Optional[Decimal] = None
    transaction_date: date
    disclosure_date: date
    asset_description: Optional[str] = None
    source_url: Optional[str] = None


class TradeCreate(TradeBase):
    """Schema for creating a trade."""
    pass


class TradeResponse(TradeBase):
    """Schema for trade response."""
    id: uuid.UUID
    created_at: datetime

    model_config = {"from_attributes": True}


class PatternDiscoveryResponse(BaseModel):
    """Schema for pattern discovery response."""
    id: uuid.UUID
    discovery_date: datetime
    politician_id: uuid.UUID
    pattern_type: str
    strength: float
    confidence: float
    parameters: dict
    metadata: Optional[dict] = None
    description: Optional[str] = None
    reviewed: bool
    deployed: bool

    model_config = {"from_attributes": True}


class AnomalyDetectionResponse(BaseModel):
    """Schema for anomaly detection response."""
    id: uuid.UUID
    detection_date: datetime
    politician_id: uuid.UUID
    anomaly_type: str
    severity: float
    evidence: dict
    description: Optional[str] = None
    investigated: bool
    false_positive: Optional[bool] = None

    model_config = {"from_attributes": True}


__all__ = [
    "PoliticianBase",
    "PoliticianCreate",
    "PoliticianResponse",
    "TradeBase",
    "TradeCreate",
    "TradeResponse",
    "PatternDiscoveryResponse",
    "AnomalyDetectionResponse",
]
