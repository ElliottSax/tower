"""Audio processing and lip sync integration.

Provides:
- AudioTrack: Audio file management
- RhubarbLipSync: Rhubarb lip sync integration
- AudioMixer: Multiple audio track mixing
- WaveformAnalyzer: Audio visualization
"""

from .lipsync import (
    MouthCue,
    LipSyncData,
    RhubarbLipSync,
    generate_lipsync,
)

from .track import (
    AudioTrack,
    AudioMixer,
    AudioEvent,
    AudioTimeline,
)

from .analysis import (
    WaveformAnalyzer,
    BeatDetector,
    get_audio_duration,
    get_audio_peaks,
)

__all__ = [
    # Lip sync
    "MouthCue",
    "LipSyncData",
    "RhubarbLipSync",
    "generate_lipsync",
    # Audio track
    "AudioTrack",
    "AudioMixer",
    "AudioEvent",
    "AudioTimeline",
    # Analysis
    "WaveformAnalyzer",
    "BeatDetector",
    "get_audio_duration",
    "get_audio_peaks",
]
