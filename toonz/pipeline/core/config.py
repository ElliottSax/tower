"""Configuration management for animation projects."""

import os
import json
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional


@dataclass
class OutputConfig:
    """Output configuration."""
    format: str = "mp4"
    codec: str = "h264"
    quality: str = "high"
    width: int = 1920
    height: int = 1080
    fps: float = 30.0


@dataclass
class RhubarbConfig:
    """Rhubarb lip sync configuration."""
    executable: str = "rhubarb"
    extended_shapes: str = "GHX"
    recognizer: str = "pocketSphinx"  # or "phonetic"


@dataclass
class Config:
    """Project configuration."""
    name: str = "untitled"
    version: str = "1.0"
    project_dir: str = "."

    # Paths
    assets_dir: str = "assets"
    output_dir: str = "output"
    cache_dir: str = ".cache"

    # Output settings
    output: OutputConfig = field(default_factory=OutputConfig)

    # Tool settings
    rhubarb: RhubarbConfig = field(default_factory=RhubarbConfig)

    # FFmpeg settings
    ffmpeg_executable: str = "ffmpeg"

    @classmethod
    def load(cls, project_dir: str) -> "Config":
        """Load configuration from a project directory."""
        config_path = Path(project_dir) / "pipeline.json"

        if config_path.exists():
            with open(config_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Parse nested configs
            if 'output' in data:
                data['output'] = OutputConfig(**data['output'])
            if 'rhubarb' in data:
                data['rhubarb'] = RhubarbConfig(**data['rhubarb'])

            config = cls(**data)
        else:
            config = cls(project_dir=project_dir)

        config.project_dir = project_dir
        return config

    def save(self, path: Optional[str] = None) -> None:
        """Save configuration to file."""
        if path is None:
            path = Path(self.project_dir) / "pipeline.json"

        data = asdict(self)

        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)

    def get_assets_path(self) -> Path:
        """Get the full path to assets directory."""
        return Path(self.project_dir) / self.assets_dir

    def get_output_path(self) -> Path:
        """Get the full path to output directory."""
        return Path(self.project_dir) / self.output_dir

    def get_cache_path(self) -> Path:
        """Get the full path to cache directory."""
        return Path(self.project_dir) / self.cache_dir

    def ensure_directories(self) -> None:
        """Create all required directories if they don't exist."""
        self.get_assets_path().mkdir(parents=True, exist_ok=True)
        self.get_output_path().mkdir(parents=True, exist_ok=True)
        self.get_cache_path().mkdir(parents=True, exist_ok=True)
