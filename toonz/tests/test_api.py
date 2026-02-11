#!/usr/bin/env python3
"""Tests for Toonz Animation API."""

import pytest
from fastapi.testclient import TestClient
from pipeline.api import app, JOBS, USAGE, OUTPUT_DIR


@pytest.fixture
def client():
    """Create test client."""
    # Clear state
    JOBS.clear()
    USAGE.clear()
    return TestClient(app)


@pytest.fixture(autouse=True)
def setup_teardown():
    """Setup and teardown for each test."""
    # Setup
    OUTPUT_DIR.mkdir(exist_ok=True)

    yield

    # Teardown
    JOBS.clear()
    USAGE.clear()


class TestHealthEndpoints:
    """Test health check endpoints."""

    def test_root_endpoint(self, client):
        """Test root endpoint returns service info."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["service"] == "Toonz Animation API"
        assert data["status"] == "operational"

    def test_health_endpoint(self, client):
        """Test health check endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data


class TestRenderEndpoints:
    """Test render creation and management."""

    def test_create_render_minimal(self, client):
        """Test creating render with minimal parameters."""
        response = client.post(
            "/api/v1/renders",
            json={
                "audio_url": "https://example.com/audio.mp3"
            },
            params={"user_id": "test_user"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "job_id" in data
        assert data["status"] == "queued"
        assert data["progress"] == 0.0

    def test_create_render_full_params(self, client):
        """Test creating render with all parameters."""
        response = client.post(
            "/api/v1/renders",
            json={
                "audio_url": "https://example.com/audio.mp3",
                "transcript": "Hello world",
                "character_style": "business",
                "template": "explainer",
                "quality": "hd",
                "background_color": "#FF6B6B",
                "duration": 120.0,
                "webhook_url": "https://example.com/webhook"
            },
            params={"user_id": "test_user"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["metadata"]["quality"] == "hd"
        assert data["metadata"]["template"] == "explainer"
        assert data["metadata"]["character"] == "business"

    def test_create_render_invalid_background(self, client):
        """Test creating render with invalid background color."""
        response = client.post(
            "/api/v1/renders",
            json={
                "background_color": "invalid"
            },
            params={"user_id": "test_user"}
        )
        assert response.status_code == 422  # Validation error

    def test_get_render_status(self, client):
        """Test getting render status."""
        # Create render
        create_response = client.post(
            "/api/v1/renders",
            json={"audio_url": "https://example.com/audio.mp3"},
            params={"user_id": "test_user"}
        )
        job_id = create_response.json()["job_id"]

        # Get status
        response = client.get(f"/api/v1/renders/{job_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["job_id"] == job_id
        assert "status" in data
        assert "progress" in data

    def test_get_render_status_not_found(self, client):
        """Test getting status for non-existent job."""
        response = client.get("/api/v1/renders/nonexistent-job-id")
        assert response.status_code == 404

    def test_delete_render(self, client):
        """Test deleting a render job."""
        # Create render
        create_response = client.post(
            "/api/v1/renders",
            json={"audio_url": "https://example.com/audio.mp3"},
            params={"user_id": "test_user"}
        )
        job_id = create_response.json()["job_id"]

        # Delete
        response = client.delete(f"/api/v1/renders/{job_id}")
        assert response.status_code == 200

        # Verify deleted
        response = client.get(f"/api/v1/renders/{job_id}")
        assert response.status_code == 404


class TestBatchEndpoints:
    """Test batch rendering."""

    def test_create_batch(self, client):
        """Test creating batch render jobs."""
        response = client.post(
            "/api/v1/batch",
            json={
                "renders": [
                    {"audio_url": "https://example.com/audio1.mp3"},
                    {"audio_url": "https://example.com/audio2.mp3"},
                    {"audio_url": "https://example.com/audio3.mp3"}
                ],
                "priority": 5
            },
            params={"user_id": "test_user"}
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        assert all(job["status"] == "queued" for job in data)

    def test_create_batch_empty(self, client):
        """Test creating batch with no renders."""
        response = client.post(
            "/api/v1/batch",
            json={"renders": []},
            params={"user_id": "test_user"}
        )
        assert response.status_code == 422  # Validation error


class TestDiscoveryEndpoints:
    """Test discovery endpoints."""

    def test_list_templates(self, client):
        """Test listing animation templates."""
        response = client.get("/api/v1/templates")
        assert response.status_code == 200
        data = response.json()
        assert "templates" in data
        assert len(data["templates"]) > 0
        template = data["templates"][0]
        assert "id" in template
        assert "name" in template
        assert "description" in template

    def test_list_characters(self, client):
        """Test listing character styles."""
        response = client.get("/api/v1/characters")
        assert response.status_code == 200
        data = response.json()
        assert "characters" in data
        assert len(data["characters"]) > 0
        character = data["characters"][0]
        assert "id" in character
        assert "name" in character

    def test_get_pricing(self, client):
        """Test getting pricing information."""
        response = client.get("/api/v1/pricing")
        assert response.status_code == 200
        data = response.json()
        assert "render_pricing" in data
        assert "subscription_tiers" in data
        assert "currency" in data
        assert data["currency"] == "USD"


class TestUsageEndpoints:
    """Test usage tracking and billing."""

    def test_get_usage_new_user(self, client):
        """Test getting usage for new user returns 404."""
        response = client.get("/api/v1/usage/new_user")
        assert response.status_code == 404

    def test_get_usage_after_render(self, client):
        """Test getting usage after creating render."""
        # Create render
        client.post(
            "/api/v1/renders",
            json={"audio_url": "https://example.com/audio.mp3"},
            params={"user_id": "test_user"}
        )

        # Get usage
        response = client.get("/api/v1/usage/test_user")
        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == "test_user"
        assert data["renders_this_month"] == 1
        assert data["total_cost"] > 0

    def test_rate_limiting(self, client):
        """Test rate limiting enforcement."""
        # Create renders up to limit
        for _ in range(10):  # Free tier limit
            response = client.post(
                "/api/v1/renders",
                json={"audio_url": "https://example.com/audio.mp3"},
                params={"user_id": "rate_limit_user"}
            )
            assert response.status_code == 200

        # Next one should be rate limited
        response = client.post(
            "/api/v1/renders",
            json={"audio_url": "https://example.com/audio.mp3"},
            params={"user_id": "rate_limit_user"}
        )
        assert response.status_code == 429


class TestAdminEndpoints:
    """Test admin endpoints."""

    def test_get_admin_stats(self, client):
        """Test getting admin statistics."""
        # Create some jobs
        for i in range(3):
            client.post(
                "/api/v1/renders",
                json={"audio_url": f"https://example.com/audio{i}.mp3"},
                params={"user_id": f"user_{i}"}
            )

        # Get stats
        response = client.get("/api/v1/admin/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["total_jobs"] == 3
        assert data["total_users"] == 3
        assert "total_revenue" in data


class TestValidation:
    """Test request validation."""

    def test_invalid_quality(self, client):
        """Test invalid quality parameter."""
        response = client.post(
            "/api/v1/renders",
            json={
                "audio_url": "https://example.com/audio.mp3",
                "quality": "invalid_quality"
            },
            params={"user_id": "test_user"}
        )
        assert response.status_code == 422

    def test_invalid_template(self, client):
        """Test invalid template parameter."""
        response = client.post(
            "/api/v1/renders",
            json={
                "audio_url": "https://example.com/audio.mp3",
                "template": "invalid_template"
            },
            params={"user_id": "test_user"}
        )
        assert response.status_code == 422

    def test_invalid_character(self, client):
        """Test invalid character style."""
        response = client.post(
            "/api/v1/renders",
            json={
                "audio_url": "https://example.com/audio.mp3",
                "character_style": "invalid_character"
            },
            params={"user_id": "test_user"}
        )
        assert response.status_code == 422


class TestWebhooks:
    """Test webhook functionality."""

    def test_webhook_test_endpoint(self, client):
        """Test webhook test endpoint."""
        response = client.post(
            "/api/v1/webhook-test",
            params={"webhook_url": "https://example.com/webhook"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "webhook configured"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
