"""Tests for lead management API endpoints."""

import pytest
from tests.conftest_api import *  # noqa: import fixtures
from tests.factories import create_business, create_contact, create_lead_score, create_touch, create_campaign


class TestListLeads:
    def test_empty_database(self, client):
        response = client.get("/api/leads")
        assert response.status_code == 200
        data = response.json()
        assert data["leads"] == []
        assert data["count"] == 0

    def test_returns_scored_businesses(self, client, db_session):
        biz = create_business(db_session)
        create_contact(db_session, biz["id"])
        create_lead_score(db_session, biz["id"])

        response = client.get("/api/leads")
        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 1
        assert data["leads"][0]["name"] == biz["name"]
        assert data["leads"][0]["composite_score"] == 0.75

    def test_filter_by_tier_hot(self, client, db_session):
        hot_biz = create_business(db_session, name="Hot Biz")
        create_lead_score(db_session, hot_biz["id"], composite_score=0.85, score_tier="hot")

        cold_biz = create_business(db_session, name="Cold Biz")
        create_lead_score(db_session, cold_biz["id"], composite_score=0.2, score_tier="cold")

        response = client.get("/api/leads?tier=hot")
        data = response.json()
        assert data["count"] == 1
        assert data["leads"][0]["name"] == "Hot Biz"

    def test_filter_by_state(self, client, db_session):
        tx_biz = create_business(db_session, name="TX Biz", state="TX")
        create_lead_score(db_session, tx_biz["id"])

        ca_biz = create_business(db_session, name="CA Biz", state="CA")
        create_lead_score(db_session, ca_biz["id"])

        response = client.get("/api/leads?state=TX")
        data = response.json()
        assert data["count"] == 1
        assert data["leads"][0]["state"] == "TX"

    def test_filter_by_industry(self, client, db_session):
        hvac_biz = create_business(db_session, name="HVAC Co", industry="HVAC")
        create_lead_score(db_session, hvac_biz["id"])

        plumb_biz = create_business(db_session, name="Plumb Co", industry="Plumbing")
        create_lead_score(db_session, plumb_biz["id"])

        response = client.get("/api/leads?industry=HVAC")
        data = response.json()
        assert data["count"] == 1
        assert data["leads"][0]["industry"] == "HVAC"

    def test_pagination(self, client, db_session):
        for i in range(5):
            biz = create_business(db_session, name=f"Biz {i}")
            create_lead_score(db_session, biz["id"], composite_score=0.5 + i * 0.05)

        response = client.get("/api/leads?limit=2&offset=0")
        data = response.json()
        assert data["count"] == 2

    def test_includes_owner_info(self, client, db_session):
        biz = create_business(db_session)
        create_contact(db_session, biz["id"], full_name="Jane Doe", email="jane@test.com")
        create_lead_score(db_session, biz["id"])

        response = client.get("/api/leads")
        data = response.json()
        assert data["leads"][0]["owner_name"] == "Jane Doe"
        assert data["leads"][0]["email"] == "jane@test.com"


class TestLeadStats:
    def test_empty_database(self, client):
        response = client.get("/api/leads/stats")
        assert response.status_code == 200
        data = response.json()
        assert "by_tier" in data
        assert "score_distribution" in data

    def test_tier_counts(self, client, db_session):
        for i, tier in enumerate(["hot", "hot", "warm", "cold"]):
            score = {"hot": 0.8, "warm": 0.55, "cold": 0.3}[tier]
            biz = create_business(db_session, name=f"Biz {i}")
            create_lead_score(db_session, biz["id"], composite_score=score, score_tier=tier)

        response = client.get("/api/leads/stats")
        data = response.json()
        assert data["by_tier"]["hot"] == 2
        assert data["by_tier"]["warm"] == 1
        assert data["by_tier"]["cold"] == 1

    def test_top_industries(self, client, db_session):
        for i in range(3):
            biz = create_business(db_session, name=f"HVAC {i}", industry="HVAC")
            create_lead_score(db_session, biz["id"])

        biz = create_business(db_session, name="Plumb 1", industry="Plumbing")
        create_lead_score(db_session, biz["id"])

        response = client.get("/api/leads/stats")
        data = response.json()
        assert len(data["top_industries"]) >= 1
        assert data["top_industries"][0]["industry"] == "HVAC"
        assert data["top_industries"][0]["count"] == 3


class TestGetLead:
    def test_existing_lead(self, client, db_session):
        biz = create_business(db_session)
        create_lead_score(db_session, biz["id"])

        response = client.get(f"/api/leads/{biz['id']}")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == biz["name"]
        assert "composite_score" in data

    def test_nonexistent_lead(self, client):
        response = client.get("/api/leads/00000000-0000-0000-0000-000000000000")
        assert response.status_code == 404

    def test_includes_contacts(self, client, db_session):
        biz = create_business(db_session)
        create_contact(db_session, biz["id"])
        create_lead_score(db_session, biz["id"])

        response = client.get(f"/api/leads/{biz['id']}")
        data = response.json()
        assert len(data["contacts"]) == 1
        assert data["contacts"][0]["full_name"] == "John Smith"

    def test_includes_touches(self, client, db_session):
        biz = create_business(db_session)
        contact = create_contact(db_session, biz["id"])
        create_lead_score(db_session, biz["id"])
        campaign = create_campaign(db_session)
        create_touch(db_session, campaign["id"], biz["id"], contact["id"])

        response = client.get(f"/api/leads/{biz['id']}")
        data = response.json()
        assert len(data["touches"]) == 1
