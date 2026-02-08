"""Tests for business management API endpoints."""

import pytest
from tests.conftest_api import *  # noqa: import fixtures
from tests.factories import create_business, create_contact, create_lead_score, create_deal


class TestListBusinesses:
    def test_empty_database(self, client):
        response = client.get("/api/businesses")
        assert response.status_code == 200
        data = response.json()
        assert data["businesses"] == []
        assert data["total"] == 0

    def test_list_with_data(self, client, db_session):
        create_business(db_session, name="Biz A")
        create_business(db_session, name="Biz B")

        response = client.get("/api/businesses")
        data = response.json()
        assert data["total"] == 2
        assert len(data["businesses"]) == 2

    def test_search_by_name(self, client, db_session):
        create_business(db_session, name="Alpha HVAC")
        create_business(db_session, name="Beta Plumbing")

        response = client.get("/api/businesses?search=Alpha")
        data = response.json()
        assert data["total"] == 1
        assert data["businesses"][0]["name"] == "Alpha HVAC"

    def test_filter_by_state(self, client, db_session):
        create_business(db_session, name="TX Co", state="TX")
        create_business(db_session, name="CA Co", state="CA")

        response = client.get("/api/businesses?state=CA")
        data = response.json()
        assert data["total"] == 1
        assert data["businesses"][0]["state"] == "CA"

    def test_pagination_total(self, client, db_session):
        for i in range(5):
            create_business(db_session, name=f"Biz {i}")

        response = client.get("/api/businesses?limit=2")
        data = response.json()
        assert len(data["businesses"]) == 2
        assert data["total"] == 5


class TestOverview:
    def test_empty_database(self, client):
        response = client.get("/api/businesses/overview")
        assert response.status_code == 200
        data = response.json()
        assert data["total_businesses"] == 0
        assert data["hot_leads"] == 0
        assert data["active_deals"] == 0

    def test_counts(self, client, db_session):
        biz = create_business(db_session)
        create_contact(db_session, biz["id"], email="test@test.com")
        create_lead_score(db_session, biz["id"], score_tier="hot")
        create_deal(db_session, biz["id"])

        response = client.get("/api/businesses/overview")
        data = response.json()
        assert data["total_businesses"] == 1
        assert data["with_email"] == 1
        assert data["hot_leads"] == 1
        assert data["active_deals"] == 1


class TestGetBusiness:
    def test_existing_business(self, client, db_session):
        biz = create_business(db_session)

        response = client.get(f"/api/businesses/{biz['id']}")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == biz["name"]

    def test_nonexistent_business(self, client):
        response = client.get("/api/businesses/00000000-0000-0000-0000-000000000000")
        assert response.status_code == 404

    def test_includes_contacts(self, client, db_session):
        biz = create_business(db_session)
        create_contact(db_session, biz["id"])

        response = client.get(f"/api/businesses/{biz['id']}")
        data = response.json()
        assert len(data["contacts"]) == 1

    def test_includes_lead_score(self, client, db_session):
        biz = create_business(db_session)
        create_lead_score(db_session, biz["id"], composite_score=0.82)

        response = client.get(f"/api/businesses/{biz['id']}")
        data = response.json()
        assert data["lead_score"] is not None
        assert float(data["lead_score"]["composite_score"]) == pytest.approx(0.82)
