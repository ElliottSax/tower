"""Tests for campaign management API endpoints."""

import pytest
from tests.conftest_api import *  # noqa: import fixtures
from tests.factories import create_campaign, create_business, create_contact, create_touch


class TestListCampaigns:
    def test_empty_database(self, client):
        response = client.get("/api/campaigns")
        assert response.status_code == 200
        data = response.json()
        assert data["campaigns"] == []

    def test_list_with_data(self, client, db_session):
        create_campaign(db_session, name="Campaign A")
        create_campaign(db_session, name="Campaign B", status="paused")

        response = client.get("/api/campaigns")
        data = response.json()
        assert len(data["campaigns"]) == 2

    def test_filter_by_status(self, client, db_session):
        create_campaign(db_session, name="Active One", status="active")
        create_campaign(db_session, name="Paused One", status="paused")

        response = client.get("/api/campaigns?status=active")
        data = response.json()
        assert len(data["campaigns"]) == 1
        assert data["campaigns"][0]["name"] == "Active One"


class TestCreateCampaign:
    def test_create_minimal(self, client):
        response = client.post("/api/campaigns", json={"name": "New Campaign"})
        assert response.status_code == 200
        data = response.json()
        assert "id" in data
        assert data["status"] == "created"

    def test_create_with_fields(self, client):
        response = client.post("/api/campaigns", json={
            "name": "Full Campaign",
            "campaign_type": "cold_email",
            "target_score_min": 0.60,
            "target_score_max": 0.90,
            "daily_send_limit": 25,
            "use_ai_personalization": True,
        })
        assert response.status_code == 200
        data = response.json()
        assert "id" in data


class TestCampaignStats:
    def test_calculates_rates(self, client, db_session):
        create_campaign(
            db_session,
            name="Stats Test",
            total_sent=200,
            total_delivered=190,
            total_opened=80,
            total_replied=15,
        )

        response = client.get("/api/campaigns/stats")
        data = response.json()
        assert len(data["campaigns"]) == 1
        camp = data["campaigns"][0]
        assert float(camp["open_rate"]) == pytest.approx(42.1, abs=0.1)
        assert float(camp["reply_rate"]) == pytest.approx(7.5, abs=0.1)


class TestGetCampaign:
    def test_existing_campaign(self, client, db_session):
        camp = create_campaign(db_session)

        response = client.get(f"/api/campaigns/{camp['id']}")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == camp["name"]

    def test_nonexistent_campaign(self, client):
        response = client.get("/api/campaigns/00000000-0000-0000-0000-000000000000")
        assert response.status_code == 404

    def test_includes_touches(self, client, db_session):
        camp = create_campaign(db_session)
        biz = create_business(db_session)
        contact = create_contact(db_session, biz["id"])
        create_touch(db_session, camp["id"], biz["id"], contact["id"])

        response = client.get(f"/api/campaigns/{camp['id']}")
        data = response.json()
        assert len(data["touches"]) == 1


class TestUpdateCampaignStatus:
    def test_activate(self, client, db_session):
        camp = create_campaign(db_session, status="draft")

        response = client.patch(f"/api/campaigns/{camp['id']}/status?status=active")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "active"

    def test_pause(self, client, db_session):
        camp = create_campaign(db_session, status="active")

        response = client.patch(f"/api/campaigns/{camp['id']}/status?status=paused")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "paused"

    def test_invalid_status(self, client, db_session):
        camp = create_campaign(db_session)

        response = client.patch(f"/api/campaigns/{camp['id']}/status?status=invalid")
        assert response.status_code == 422  # validation error
