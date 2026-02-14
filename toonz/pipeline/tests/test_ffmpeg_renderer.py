"""Tests for renderers/ffmpeg_renderer.py module."""

import json
from pathlib import Path
from unittest.mock import patch, MagicMock, call
import subprocess

import pytest
from PIL import Image

from pipeline.renderers.ffmpeg_renderer import (
    FFmpegRenderer,
    FFmpegProbeInfo,
)
from pipeline.renderers.base import RenderProgress


class TestFFmpegRendererCreation:
    """Tests for FFmpegRenderer initialization."""

    @patch("subprocess.run")
    def test_creation_defaults(self, mock_run):
        """Test renderer creation with defaults."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer()

        assert renderer.codec == "h264"
        assert renderer.quality == "high"
        assert renderer.include_audio is True
        assert renderer.ffmpeg_path == "ffmpeg"
        assert renderer.threads == 0
        assert renderer.pixel_format == "yuv420p"

    @patch("subprocess.run")
    def test_creation_custom(self, mock_run):
        """Test renderer creation with custom values."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer(
            codec="h265",
            quality="medium",
            audio=False,
            ffmpeg_path="/usr/local/bin/ffmpeg",
            threads=4,
            pixel_format="yuv444p",
            extra_args=["-tune", "animation"]
        )

        assert renderer.codec == "h265"
        assert renderer.quality == "medium"
        assert renderer.include_audio is False
        assert renderer.ffmpeg_path == "/usr/local/bin/ffmpeg"
        assert renderer.threads == 4
        assert renderer.pixel_format == "yuv444p"
        assert renderer.extra_args == ["-tune", "animation"]

    @patch("subprocess.run")
    def test_verify_ffmpeg_called(self, mock_run):
        """Test FFmpeg verification is called on init."""
        mock_run.return_value = MagicMock(returncode=0)

        FFmpegRenderer()

        mock_run.assert_called_once()
        args = mock_run.call_args[0][0]
        assert "ffmpeg" in args
        assert "-version" in args

    @patch("subprocess.run")
    def test_verify_ffmpeg_not_found(self, mock_run):
        """Test error when FFmpeg not found."""
        mock_run.side_effect = FileNotFoundError()

        with pytest.raises(RuntimeError, match="not found"):
            FFmpegRenderer()

    @patch("subprocess.run")
    def test_verify_ffmpeg_error(self, mock_run):
        """Test error when FFmpeg returns error."""
        mock_run.return_value = MagicMock(returncode=1, stderr="Error message")

        with pytest.raises(RuntimeError, match="returned error"):
            FFmpegRenderer()


class TestFFmpegRendererPresets:
    """Tests for FFmpegRenderer presets and codec mappings."""

    def test_presets_defined(self):
        """Test all quality presets are defined."""
        for codec in ["h264", "h265", "vp9", "prores"]:
            assert codec in FFmpegRenderer.PRESETS
            for quality in ["low", "medium", "high", "lossless"]:
                assert quality in FFmpegRenderer.PRESETS[codec]

    def test_codec_libs_defined(self):
        """Test codec library mappings are defined."""
        expected_codecs = ["h264", "h265", "hevc", "vp9", "vp8", "prores", "mpeg4", "gif"]
        for codec in expected_codecs:
            assert codec in FFmpegRenderer.CODEC_LIBS

    def test_h264_presets(self):
        """Test H264 preset values."""
        h264 = FFmpegRenderer.PRESETS["h264"]
        assert h264["high"]["crf"] == "18"
        assert h264["low"]["crf"] == "28"

    def test_codec_mapping(self):
        """Test codec to library mapping."""
        assert FFmpegRenderer.CODEC_LIBS["h264"] == "libx264"
        assert FFmpegRenderer.CODEC_LIBS["h265"] == "libx265"
        assert FFmpegRenderer.CODEC_LIBS["vp9"] == "libvpx-vp9"


class TestFFmpegRendererCodecArgs:
    """Tests for _get_codec_args method."""

    @patch("subprocess.run")
    def test_get_codec_args_h264(self, mock_run):
        """Test codec args for H264."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer(codec="h264", quality="high")
        args = renderer._get_codec_args()

        assert "-c:v" in args
        assert "libx264" in args
        assert "-crf" in args
        assert "18" in args
        assert "-preset" in args
        assert "slow" in args

    @patch("subprocess.run")
    def test_get_codec_args_vp9(self, mock_run):
        """Test codec args for VP9."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer(codec="vp9", quality="medium")
        args = renderer._get_codec_args()

        assert "libvpx-vp9" in args
        assert "-cpu-used" in args

    @patch("subprocess.run")
    def test_get_codec_args_pixel_format(self, mock_run):
        """Test pixel format is included."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer(pixel_format="yuv420p")
        args = renderer._get_codec_args()

        assert "-pix_fmt" in args
        assert "yuv420p" in args


class TestFFmpegRendererAudioArgs:
    """Tests for _get_audio_args method."""

    @patch("subprocess.run")
    def test_audio_args_no_audio(self, mock_run):
        """Test args when no audio."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer(audio=False)
        args = renderer._get_audio_args(None)

        assert "-an" in args

    @patch("subprocess.run")
    def test_audio_args_with_path(self, mock_run):
        """Test args with audio path."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer(audio=True)
        args = renderer._get_audio_args("/path/to/audio.wav")

        assert "-i" in args
        assert "/path/to/audio.wav" in args
        assert "-c:a" in args
        assert "aac" in args

    @patch("subprocess.run")
    def test_audio_args_disabled_with_path(self, mock_run):
        """Test audio disabled even with path."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer(audio=False)
        args = renderer._get_audio_args("/path/to/audio.wav")

        assert "-an" in args


class TestFFmpegRendererEncode:
    """Tests for encode_video method."""

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    @patch("shutil.rmtree")
    def test_encode_video_empty_frames(self, mock_rmtree, mock_popen, mock_run):
        """Test encoding with empty frames raises error."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer()

        with pytest.raises(ValueError, match="No frames"):
            renderer.encode_video([], "output.mp4", 30.0)

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    @patch("shutil.rmtree")
    @patch("tempfile.mkdtemp")
    def test_encode_video_success(self, mock_mkdtemp, mock_rmtree, mock_popen, mock_run, temp_dir):
        """Test successful video encoding."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_mkdtemp.return_value = str(temp_dir)

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = ("", "")
        mock_popen.return_value = mock_process

        renderer = FFmpegRenderer()
        frames = [Image.new('RGB', (100, 100)) for _ in range(5)]

        output_path = str(temp_dir / "output.mp4")
        result = renderer.encode_video(frames, output_path, 30.0)

        assert result == output_path
        mock_popen.assert_called_once()

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    @patch("shutil.rmtree")
    @patch("tempfile.mkdtemp")
    def test_encode_video_with_progress(self, mock_mkdtemp, mock_rmtree, mock_popen, mock_run, temp_dir):
        """Test encoding with progress callback."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_mkdtemp.return_value = str(temp_dir)

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = ("", "")
        mock_popen.return_value = mock_process

        renderer = FFmpegRenderer()
        frames = [Image.new('RGB', (100, 100)) for _ in range(3)]

        progress_updates = []
        def on_progress(progress):
            progress_updates.append(progress.current_frame)

        output_path = str(temp_dir / "output.mp4")
        renderer.encode_video(frames, output_path, 30.0, on_progress=on_progress)

        # Should have progress updates
        assert len(progress_updates) > 0

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    @patch("shutil.rmtree")
    @patch("tempfile.mkdtemp")
    def test_encode_video_failure(self, mock_mkdtemp, mock_rmtree, mock_popen, mock_run, temp_dir):
        """Test encoding failure handling."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_mkdtemp.return_value = str(temp_dir)

        mock_process = MagicMock()
        mock_process.returncode = 1
        mock_process.communicate.return_value = ("", "FFmpeg error")
        mock_popen.return_value = mock_process

        renderer = FFmpegRenderer()
        frames = [Image.new('RGB', (100, 100))]

        with pytest.raises(RuntimeError, match="encoding failed"):
            renderer.encode_video(frames, "output.mp4", 30.0)

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    @patch("shutil.rmtree")
    @patch("tempfile.mkdtemp")
    def test_encode_video_cleans_up(self, mock_mkdtemp, mock_rmtree, mock_popen, mock_run, temp_dir):
        """Test temp directory is cleaned up."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_mkdtemp.return_value = str(temp_dir)

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = ("", "")
        mock_popen.return_value = mock_process

        renderer = FFmpegRenderer()
        frames = [Image.new('RGB', (100, 100))]

        renderer.encode_video(frames, str(temp_dir / "output.mp4"), 30.0)

        mock_rmtree.assert_called_once()

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    @patch("shutil.rmtree")
    @patch("tempfile.mkdtemp")
    def test_encode_video_rgba_conversion(self, mock_mkdtemp, mock_rmtree, mock_popen, mock_run, temp_dir):
        """Test RGBA frames are converted to RGB."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_mkdtemp.return_value = str(temp_dir)

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = ("", "")
        mock_popen.return_value = mock_process

        renderer = FFmpegRenderer()
        frames = [Image.new('RGBA', (100, 100), (255, 0, 0, 128))]

        renderer.encode_video(frames, str(temp_dir / "output.mp4"), 30.0)

        # Should have created frame file
        frame_files = list(temp_dir.glob("frame_*.png"))
        assert len(frame_files) == 1


class TestFFmpegRendererConcatenate:
    """Tests for concatenate_videos method."""

    @patch("subprocess.run")
    def test_concatenate_empty_list(self, mock_run):
        """Test concatenate with empty list raises error."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer()

        with pytest.raises(ValueError, match="No videos"):
            renderer.concatenate_videos([], "output.mp4")

    @patch("subprocess.run")
    def test_concatenate_success(self, mock_run):
        """Test successful video concatenation."""
        # First call for init verification, second for actual concat
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer()

        video_paths = ["/video1.mp4", "/video2.mp4"]
        result = renderer.concatenate_videos(video_paths, "output.mp4")

        assert result == "output.mp4"
        # Should have been called twice (init + concat)
        assert mock_run.call_count == 2

    @patch("subprocess.run")
    def test_concatenate_failure(self, mock_run):
        """Test concatenation failure handling."""
        # First call succeeds (init), second fails (concat)
        mock_run.side_effect = [
            MagicMock(returncode=0),
            MagicMock(returncode=1, stderr="Concat error")
        ]

        renderer = FFmpegRenderer()

        with pytest.raises(RuntimeError, match="concat failed"):
            renderer.concatenate_videos(["/video1.mp4"], "output.mp4")


class TestFFmpegRendererAddAudio:
    """Tests for add_audio_to_video method."""

    @patch("subprocess.run")
    def test_add_audio_success(self, mock_run):
        """Test successful audio addition."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer()

        result = renderer.add_audio_to_video(
            "/video.mp4",
            "/audio.wav",
            "/output.mp4"
        )

        assert result == "/output.mp4"
        assert mock_run.call_count == 2  # init + add_audio

    @patch("subprocess.run")
    def test_add_audio_with_offset(self, mock_run):
        """Test audio addition with offset."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer()

        renderer.add_audio_to_video(
            "/video.mp4",
            "/audio.wav",
            "/output.mp4",
            audio_offset=2.5
        )

        # Check offset was included in command
        add_audio_call = mock_run.call_args_list[1]
        cmd = add_audio_call[0][0]
        assert "-itsoffset" in cmd
        assert "2.5" in cmd

    @patch("subprocess.run")
    def test_add_audio_failure(self, mock_run):
        """Test audio addition failure."""
        mock_run.side_effect = [
            MagicMock(returncode=0),
            MagicMock(returncode=1, stderr="Audio merge error")
        ]

        renderer = FFmpegRenderer()

        with pytest.raises(RuntimeError, match="audio merge failed"):
            renderer.add_audio_to_video("/video.mp4", "/audio.wav", "/output.mp4")


class TestFFmpegRendererFormats:
    """Tests for supported formats."""

    @patch("subprocess.run")
    def test_get_supported_formats(self, mock_run):
        """Test getting supported formats."""
        mock_run.return_value = MagicMock(returncode=0)

        renderer = FFmpegRenderer()
        formats = renderer.get_supported_formats()

        assert "mp4" in formats
        assert "webm" in formats
        assert "mov" in formats
        assert "avi" in formats
        assert "mkv" in formats
        assert "gif" in formats


class TestFFmpegProbeInfo:
    """Tests for FFmpegProbeInfo class."""

    def test_creation(self):
        """Test probe info creation."""
        probe = FFmpegProbeInfo()
        assert probe.ffprobe_path == "ffprobe"

        probe_custom = FFmpegProbeInfo(ffprobe_path="/usr/local/bin/ffprobe")
        assert probe_custom.ffprobe_path == "/usr/local/bin/ffprobe"

    @patch("subprocess.run")
    def test_get_duration_success(self, mock_run):
        """Test getting duration."""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout='{"format": {"duration": "120.5"}}'
        )

        probe = FFmpegProbeInfo()
        duration = probe.get_duration("/video.mp4")

        assert duration == 120.5

    @patch("subprocess.run")
    def test_get_duration_failure(self, mock_run):
        """Test duration probe failure."""
        mock_run.return_value = MagicMock(
            returncode=1,
            stderr="Probe error"
        )

        probe = FFmpegProbeInfo()

        with pytest.raises(RuntimeError, match="FFprobe failed"):
            probe.get_duration("/video.mp4")

    @patch("subprocess.run")
    def test_get_video_info_success(self, mock_run):
        """Test getting video info."""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({
                "streams": [{
                    "width": 1920,
                    "height": 1080,
                    "r_frame_rate": "30/1",
                    "codec_name": "h264",
                    "duration": "60.0"
                }]
            })
        )

        probe = FFmpegProbeInfo()
        info = probe.get_video_info("/video.mp4")

        assert info["width"] == 1920
        assert info["height"] == 1080
        assert info["fps"] == 30.0
        assert info["codec"] == "h264"
        assert info["duration"] == 60.0

    @patch("subprocess.run")
    def test_get_video_info_fractional_fps(self, mock_run):
        """Test video info with fractional fps."""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({
                "streams": [{
                    "width": 1920,
                    "height": 1080,
                    "r_frame_rate": "24000/1001",
                    "codec_name": "h264",
                    "duration": "60.0"
                }]
            })
        )

        probe = FFmpegProbeInfo()
        info = probe.get_video_info("/video.mp4")

        assert abs(info["fps"] - 23.976) < 0.01

    @patch("subprocess.run")
    def test_get_video_info_no_stream(self, mock_run):
        """Test video info with no video stream."""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout='{"streams": []}'
        )

        probe = FFmpegProbeInfo()

        with pytest.raises(ValueError, match="No video stream"):
            probe.get_video_info("/audio.mp3")

    @patch("subprocess.run")
    def test_get_video_info_failure(self, mock_run):
        """Test video info probe failure."""
        mock_run.return_value = MagicMock(
            returncode=1,
            stderr="Probe error"
        )

        probe = FFmpegProbeInfo()

        with pytest.raises(RuntimeError, match="FFprobe failed"):
            probe.get_video_info("/video.mp4")


class TestFFmpegRendererIntegration:
    """Integration tests for FFmpeg renderer."""

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    @patch("shutil.rmtree")
    @patch("tempfile.mkdtemp")
    def test_full_render_workflow(self, mock_mkdtemp, mock_rmtree, mock_popen, mock_run, temp_dir):
        """Test complete rendering workflow."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_mkdtemp.return_value = str(temp_dir)

        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.communicate.return_value = ("", "")
        mock_popen.return_value = mock_process

        # Create renderer with custom settings
        renderer = FFmpegRenderer(
            codec="h264",
            quality="high",
            audio=True,
            threads=4,
            extra_args=["-tune", "animation"]
        )

        # Create test frames
        frames = [
            Image.new('RGBA', (1920, 1080), (255, 0, 0, 255)),
            Image.new('RGBA', (1920, 1080), (0, 255, 0, 255)),
            Image.new('RGBA', (1920, 1080), (0, 0, 255, 255)),
        ]

        # Render
        progress_updates = []
        def on_progress(p):
            progress_updates.append(p.phase)

        output_path = str(temp_dir / "video.mp4")
        result = renderer.encode_video(
            frames,
            output_path,
            fps=30.0,
            audio_path="/audio.wav",
            on_progress=on_progress
        )

        assert result == output_path
        assert "writing frames" in progress_updates
        assert "encoding" in progress_updates
