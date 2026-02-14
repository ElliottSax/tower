"""Utility functions for the animation pipeline."""

import os
import subprocess
import json
from pathlib import Path
from typing import Optional


def ensure_dir(path: str) -> Path:
    """Ensure a directory exists, creating it if necessary."""
    p = Path(path)
    p.mkdir(parents=True, exist_ok=True)
    return p


def get_audio_duration(audio_path: str) -> float:
    """Get the duration of an audio file in seconds using ffprobe."""
    try:
        result = subprocess.run(
            [
                "ffprobe",
                "-v", "quiet",
                "-show_entries", "format=duration",
                "-of", "json",
                audio_path
            ],
            capture_output=True,
            text=True,
            check=True
        )
        data = json.loads(result.stdout)
        return float(data["format"]["duration"])
    except (subprocess.CalledProcessError, KeyError, json.JSONDecodeError) as e:
        raise RuntimeError(f"Failed to get audio duration: {e}")


def find_executable(name: str, paths: Optional[list[str]] = None) -> Optional[str]:
    """Find an executable in PATH or specified paths."""
    import shutil

    # Check standard PATH first
    exe = shutil.which(name)
    if exe:
        return exe

    # Check additional paths
    if paths:
        for path in paths:
            full_path = os.path.join(path, name)
            if os.path.isfile(full_path) and os.access(full_path, os.X_OK):
                return full_path
            # Check with common extensions on Windows
            for ext in ["", ".exe", ".bat", ".cmd"]:
                full_path_ext = full_path + ext
                if os.path.isfile(full_path_ext) and os.access(full_path_ext, os.X_OK):
                    return full_path_ext

    return None


def load_json(path: str) -> dict:
    """Load and parse a JSON file."""
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_json(path: str, data: dict, pretty: bool = True) -> None:
    """Save data to a JSON file."""
    with open(path, 'w', encoding='utf-8') as f:
        if pretty:
            json.dump(data, f, indent=2, ensure_ascii=False)
        else:
            json.dump(data, f, ensure_ascii=False)


def frames_to_time(frame: int, fps: float) -> float:
    """Convert frame number to time in seconds."""
    return frame / fps


def time_to_frames(time: float, fps: float) -> int:
    """Convert time in seconds to frame number."""
    return int(time * fps)
