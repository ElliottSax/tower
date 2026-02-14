"""Politician model - shared between main app and discovery service."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import String, DateTime, func, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from quant_shared.models.base import Base

if TYPE_CHECKING:
    from quant_shared.models.trade import Trade
    from quant_shared.models.discovery import PatternDiscovery, AnomalyDetection


class Politician(Base):
    """Politician model."""

    __tablename__ = "politicians"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    chamber: Mapped[str] = mapped_column(
        String(10),
        nullable=False,
        index=True,
    )  # 'senate' or 'house'
    party: Mapped[str | None] = mapped_column(String(20), index=True)
    state: Mapped[str | None] = mapped_column(String(2))
    bioguide_id: Mapped[str | None] = mapped_column(String(10), unique=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    # Relationships
    trades: Mapped[list["Trade"]] = relationship(
        "Trade",
        back_populates="politician",
        cascade="all, delete-orphan",
    )
    pattern_discoveries: Mapped[list["PatternDiscovery"]] = relationship(
        "PatternDiscovery",
        back_populates="politician",
        cascade="all, delete-orphan",
    )
    anomaly_detections: Mapped[list["AnomalyDetection"]] = relationship(
        "AnomalyDetection",
        back_populates="politician",
        cascade="all, delete-orphan",
    )

    # Database constraints
    __table_args__ = (
        CheckConstraint(
            "chamber IN ('senate', 'house')",
            name="valid_chamber",
        ),
    )

    def __repr__(self) -> str:
        """String representation."""
        return f"<Politician {self.name} ({self.chamber})>"
