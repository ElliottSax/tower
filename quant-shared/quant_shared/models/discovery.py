"""Discovery models - written by discovery service, read by main app."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import String, DateTime, Float, Boolean, ForeignKey, func, Text, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB, ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from quant_shared.models.base import Base

if TYPE_CHECKING:
    from quant_shared.models.politician import Politician


class PatternDiscovery(Base):
    """
    Discovered patterns from background analysis.

    Written by: discovery service
    Read by: main app (displays to users)
    """

    __tablename__ = "pattern_discoveries"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    discovery_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )
    politician_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("politicians.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    pattern_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True,
    )  # 'cycle', 'regime', 'correlation', 'leading_indicator', etc.
    strength: Mapped[float] = mapped_column(Float, nullable=False)
    confidence: Mapped[float] = mapped_column(Float, nullable=False)
    parameters: Mapped[dict] = mapped_column(JSONB, nullable=False)  # Experiment params
    metadata: Mapped[dict | None] = mapped_column(JSONB)  # Additional context
    description: Mapped[str | None] = mapped_column(Text)  # Human-readable summary
    reviewed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    deployed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    politician: Mapped["Politician"] = relationship(
        "Politician",
        back_populates="pattern_discoveries"
    )

    # Indexes
    __table_args__ = (
        Index("idx_pattern_strength", "strength", postgresql_using="btree"),
        Index("idx_pattern_confidence", "confidence", postgresql_using="btree"),
        Index("idx_pattern_deployed", "deployed", "strength", postgresql_using="btree"),
    )

    def __repr__(self) -> str:
        """String representation."""
        return f"<PatternDiscovery {self.pattern_type} strength={self.strength:.2f}>"


class AnomalyDetection(Base):
    """
    Detected anomalies from background analysis.

    Written by: discovery service
    Read by: main app (alerts, dashboards)
    """

    __tablename__ = "anomaly_detections"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    detection_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )
    politician_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("politicians.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    anomaly_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True,
    )  # 'statistical_outlier', 'model_disagreement', 'off_cycle', etc.
    severity: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        index=True,
    )  # 0-1, higher = more severe
    evidence: Mapped[dict] = mapped_column(JSONB, nullable=False)  # Supporting data
    description: Mapped[str | None] = mapped_column(Text)
    investigated: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    false_positive: Mapped[bool | None] = mapped_column(Boolean)  # null = not yet determined

    # Relationships
    politician: Mapped["Politician"] = relationship(
        "Politician",
        back_populates="anomaly_detections"
    )

    # Indexes
    __table_args__ = (
        Index("idx_anomaly_severity", "severity", postgresql_using="btree"),
        Index("idx_anomaly_investigated", "investigated", "severity", postgresql_using="btree"),
    )

    def __repr__(self) -> str:
        """String representation."""
        return f"<AnomalyDetection {self.anomaly_type} severity={self.severity:.2f}>"


class ModelExperiment(Base):
    """
    Experimental model results.

    Written by: discovery service (research tasks)
    Read by: main app (admin dashboard), discovery service (comparison)
    """

    __tablename__ = "model_experiments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    experiment_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )
    model_name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    hyperparameters: Mapped[dict] = mapped_column(JSONB, nullable=False)
    training_metrics: Mapped[dict] = mapped_column(JSONB, nullable=False)
    validation_metrics: Mapped[dict] = mapped_column(JSONB, nullable=False)
    test_metrics: Mapped[dict | None] = mapped_column(JSONB)
    dataset_info: Mapped[dict | None] = mapped_column(JSONB)
    mlflow_run_id: Mapped[str | None] = mapped_column(String(100))
    deployment_ready: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)

    # Indexes
    __table_args__ = (
        Index("idx_experiment_model", "model_name", "experiment_date", postgresql_using="btree"),
        Index("idx_experiment_ready", "deployment_ready", postgresql_using="btree"),
    )

    def __repr__(self) -> str:
        """String representation."""
        return f"<ModelExperiment {self.model_name} on {self.experiment_date:%Y-%m-%d}>"


class NetworkDiscovery(Base):
    """
    Network-level discoveries (correlations, clusters, coordination).

    Written by: discovery service (network analysis tasks)
    Read by: main app (network visualizations)
    """

    __tablename__ = "network_discoveries"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    discovery_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )
    discovery_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True,
    )  # 'cluster', 'correlation', 'coordination', 'leading_indicator'
    politicians_involved: Mapped[list[uuid.UUID]] = mapped_column(
        ARRAY(UUID(as_uuid=True)),
        nullable=False,
    )
    strength: Mapped[float] = mapped_column(Float, nullable=False)
    evidence: Mapped[dict] = mapped_column(JSONB, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    investigated: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Indexes
    __table_args__ = (
        Index("idx_network_type", "discovery_type", "strength", postgresql_using="btree"),
        Index("idx_network_investigated", "investigated", "discovery_date", postgresql_using="btree"),
    )

    def __repr__(self) -> str:
        """String representation."""
        return f"<NetworkDiscovery {self.discovery_type} with {len(self.politicians_involved)} politicians>"
