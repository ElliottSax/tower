#!/usr/bin/env python3
"""
Toonz Animation API - Python Client SDK

Simple client library for integrating Toonz animation generation into applications.

Usage:
    from client_sdk import ToonzClient

    client = ToonzClient(api_key="your-api-key")

    # Create animation from audio
    job = client.create_animation(
        audio_url="https://example.com/audio.mp3",
        template="explainer",
        quality="hd"
    )

    # Wait for completion
    result = client.wait_for_completion(job.job_id, timeout=300)

    # Download video
    client.download(job.job_id, "output.mp4")
"""

import time
import requests
from typing import Optional, Dict, Any, List
from pathlib import Path
from dataclasses import dataclass


@dataclass
class RenderJob:
    """Render job information."""
    job_id: str
    status: str
    progress: float = 0.0
    download_url: Optional[str] = None
    error: Optional[str] = None


class ToonzClient:
    """Client for Toonz Animation API."""

    def __init__(
        self,
        api_key: str,
        base_url: str = "http://localhost:8000",
        user_id: str = "default"
    ):
        """
        Initialize Toonz API client.

        Args:
            api_key: API authentication key
            base_url: Base URL of Toonz API
            user_id: User ID for billing/tracking
        """
        self.api_key = api_key
        self.base_url = base_url.rstrip('/')
        self.user_id = user_id
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_key}',
            'User-Agent': 'ToonzClient/1.0'
        })

    def create_animation(
        self,
        audio_url: Optional[str] = None,
        transcript: Optional[str] = None,
        character_style: str = "simple",
        template: str = "talking_head",
        quality: str = "standard",
        background_color: str = "#FFFFFF",
        duration: Optional[float] = None,
        webhook_url: Optional[str] = None
    ) -> RenderJob:
        """
        Create a new animation render job.

        Args:
            audio_url: URL to audio file
            transcript: Optional text transcript
            character_style: Character appearance (simple, business, cartoon, realistic)
            template: Animation template (talking_head, explainer, product_demo, etc.)
            quality: Render quality (preview, standard, hd, ultra)
            background_color: Background color as hex (#RRGGBB)
            duration: Maximum duration in seconds
            webhook_url: Callback URL when complete

        Returns:
            RenderJob with job_id and initial status
        """
        payload = {
            "audio_url": audio_url,
            "transcript": transcript,
            "character_style": character_style,
            "template": template,
            "quality": quality,
            "background_color": background_color,
            "duration": duration,
            "webhook_url": webhook_url
        }

        # Remove None values
        payload = {k: v for k, v in payload.items() if v is not None}

        response = self.session.post(
            f"{self.base_url}/api/v1/renders",
            json=payload,
            params={"user_id": self.user_id}
        )
        response.raise_for_status()

        data = response.json()
        return RenderJob(
            job_id=data['job_id'],
            status=data['status'],
            progress=data.get('progress', 0.0)
        )

    def get_status(self, job_id: str) -> RenderJob:
        """
        Get status of a render job.

        Args:
            job_id: Job ID to check

        Returns:
            RenderJob with current status
        """
        response = self.session.get(f"{self.base_url}/api/v1/renders/{job_id}")
        response.raise_for_status()

        data = response.json()
        return RenderJob(
            job_id=data['job_id'],
            status=data['status'],
            progress=data.get('progress', 0.0),
            download_url=data.get('download_url'),
            error=data.get('error')
        )

    def wait_for_completion(
        self,
        job_id: str,
        timeout: int = 300,
        poll_interval: int = 2
    ) -> RenderJob:
        """
        Wait for render job to complete.

        Args:
            job_id: Job ID to wait for
            timeout: Maximum wait time in seconds
            poll_interval: How often to poll in seconds

        Returns:
            RenderJob when completed

        Raises:
            TimeoutError: If job doesn't complete in time
            RuntimeError: If job fails
        """
        start_time = time.time()

        while time.time() - start_time < timeout:
            job = self.get_status(job_id)

            if job.status == "completed":
                return job
            elif job.status == "failed":
                raise RuntimeError(f"Render failed: {job.error}")

            time.sleep(poll_interval)

        raise TimeoutError(f"Render job {job_id} did not complete in {timeout}s")

    def download(self, job_id: str, output_path: str) -> Path:
        """
        Download completed render.

        Args:
            job_id: Job ID to download
            output_path: Local path to save file

        Returns:
            Path to downloaded file
        """
        # Check job is completed
        job = self.get_status(job_id)
        if job.status != "completed":
            raise RuntimeError(f"Job not ready for download (status: {job.status})")

        # Download file
        response = self.session.get(
            f"{self.base_url}/api/v1/renders/{job_id}/download",
            stream=True
        )
        response.raise_for_status()

        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

        return output_path

    def create_batch(
        self,
        renders: List[Dict[str, Any]],
        priority: int = 0
    ) -> List[RenderJob]:
        """
        Create multiple render jobs in batch.

        Args:
            renders: List of render requests (same format as create_animation)
            priority: Processing priority (0-10, higher is faster)

        Returns:
            List of RenderJob objects
        """
        payload = {
            "renders": renders,
            "priority": priority
        }

        response = self.session.post(
            f"{self.base_url}/api/v1/batch",
            json=payload,
            params={"user_id": self.user_id}
        )
        response.raise_for_status()

        data = response.json()
        return [
            RenderJob(
                job_id=job['job_id'],
                status=job['status'],
                progress=job.get('progress', 0.0)
            )
            for job in data
        ]

    def get_usage(self) -> Dict[str, Any]:
        """
        Get usage statistics for current user.

        Returns:
            Dictionary with usage stats including:
            - total_renders: Total renders all time
            - renders_this_month: Renders this billing period
            - renders_remaining: Remaining renders in current tier
            - total_cost: Total cost in USD
        """
        response = self.session.get(f"{self.base_url}/api/v1/usage/{self.user_id}")
        response.raise_for_status()
        return response.json()

    def get_pricing(self) -> Dict[str, Any]:
        """
        Get current pricing information.

        Returns:
            Dictionary with render pricing and subscription tiers
        """
        response = self.session.get(f"{self.base_url}/api/v1/pricing")
        response.raise_for_status()
        return response.json()

    def list_templates(self) -> List[Dict[str, str]]:
        """
        List available animation templates.

        Returns:
            List of template information including id, name, description
        """
        response = self.session.get(f"{self.base_url}/api/v1/templates")
        response.raise_for_status()
        return response.json()['templates']

    def list_characters(self) -> List[Dict[str, str]]:
        """
        List available character styles.

        Returns:
            List of character information including id, name, description
        """
        response = self.session.get(f"{self.base_url}/api/v1/characters")
        response.raise_for_status()
        return response.json()['characters']

    def delete_render(self, job_id: str) -> None:
        """
        Delete a render job and its output.

        Args:
            job_id: Job ID to delete
        """
        response = self.session.delete(f"{self.base_url}/api/v1/renders/{job_id}")
        response.raise_for_status()


# ============================================================================
# Example Usage
# ============================================================================

def example_basic_usage():
    """Example: Create simple animation."""
    client = ToonzClient(api_key="demo-key")

    # Create animation
    job = client.create_animation(
        audio_url="https://example.com/narration.mp3",
        transcript="Hello world, this is a test animation.",
        template="talking_head",
        quality="hd"
    )

    print(f"Job created: {job.job_id}")

    # Wait for completion
    result = client.wait_for_completion(job.job_id, timeout=300)
    print(f"Render complete: {result.download_url}")

    # Download
    output_file = client.download(job.job_id, "output/animation.mp4")
    print(f"Downloaded to: {output_file}")


def example_batch_rendering():
    """Example: Batch render multiple animations."""
    client = ToonzClient(api_key="demo-key")

    # Create batch of renders
    renders = [
        {
            "audio_url": f"https://example.com/audio_{i}.mp3",
            "template": "explainer",
            "quality": "standard"
        }
        for i in range(5)
    ]

    jobs = client.create_batch(renders, priority=5)
    print(f"Created {len(jobs)} jobs")

    # Wait for all to complete
    for job in jobs:
        result = client.wait_for_completion(job.job_id)
        print(f"Job {job.job_id}: {result.status}")


def example_usage_tracking():
    """Example: Check usage and pricing."""
    client = ToonzClient(api_key="demo-key")

    # Get current usage
    usage = client.get_usage()
    print(f"Renders this month: {usage['renders_this_month']}")
    print(f"Remaining renders: {usage['renders_remaining']}")
    print(f"Total cost: ${usage['total_cost']:.2f}")

    # Get pricing info
    pricing = client.get_pricing()
    print("\nRender Pricing:")
    for quality, price in pricing['render_pricing'].items():
        print(f"  {quality}: ${price}")


if __name__ == "__main__":
    # Run examples
    print("Toonz API Client SDK Examples")
    print("=" * 50)

    # Uncomment to run examples:
    # example_basic_usage()
    # example_batch_rendering()
    # example_usage_tracking()
