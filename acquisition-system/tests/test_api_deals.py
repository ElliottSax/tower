"""Tests for deal pipeline API endpoints."""

import pytest
from tests.conftest_api import *  # noqa: import fixtures
from tests.factories import create_business, create_deal


class TestListDeals:
    def test_empty_database(self, client):
        response = client.get("/api/deals")
        assert response.status_code == 200
        data = response.json()
        assert data["deals"] == []

    def test_list_active_deals(self, client, db_session):
        biz = create_business(db_session)
        create_deal(db_session, biz["id"], name="Deal A", is_active=True)
        create_deal(db_session, biz["id"], name="Deal B", is_active=False)

        response = client.get("/api/deals?active_only=true")
        data = response.json()
        assert len(data["deals"]) == 1
        assert data["deals"][0]["name"] == "Deal A"

    def test_filter_by_stage(self, client, db_session):
        biz = create_business(db_session)
        create_deal(db_session, biz["id"], name="Lead Deal", stage="lead")
        create_deal(db_session, biz["id"], name="Qualified Deal", stage="qualified")

        response = client.get("/api/deals?stage=qualified")
        data = response.json()
        assert len(data["deals"]) == 1
        assert data["deals"][0]["name"] == "Qualified Deal"

    def test_includes_business_info(self, client, db_session):
        biz = create_business(db_session, name="Target Co", industry="HVAC", state="TX")
        create_deal(db_session, biz["id"])

        response = client.get("/api/deals")
        data = response.json()
        assert data["deals"][0]["business_name"] == "Target Co"
        assert data["deals"][0]["industry"] == "HVAC"


class TestCreateDeal:
    def test_create_minimal(self, client):
        response = client.post("/api/deals", json={"name": "New Deal"})
        assert response.status_code == 200
        data = response.json()
        assert "id" in data
        assert data["status"] == "created"

    def test_create_with_business(self, client, db_session):
        biz = create_business(db_session)

        response = client.post("/api/deals", json={
            "name": "Linked Deal",
            "business_id": biz["id"],
            "asking_price": 2000000,
            "estimated_sde": 400000,
        })
        assert response.status_code == 200


class TestPipelineOverview:
    def test_empty_pipeline(self, client):
        response = client.get("/api/deals/pipeline")
        assert response.status_code == 200
        data = response.json()
        assert "pipeline" in data
        assert "stages" in data
        assert len(data["stages"]) == 8

    def test_stage_counts(self, client, db_session):
        biz = create_business(db_session)
        create_deal(db_session, biz["id"], stage="lead", asking_price=1000000)
        create_deal(db_session, biz["id"], stage="lead", asking_price=2000000)
        create_deal(db_session, biz["id"], stage="qualified", asking_price=1500000)

        response = client.get("/api/deals/pipeline")
        data = response.json()
        stages = {s["stage"]: s for s in data["pipeline"]}
        assert stages["lead"]["count"] == 2
        assert stages["lead"]["total_value"] == 3000000
        assert stages["qualified"]["count"] == 1

    def test_stage_ordering(self, client, db_session):
        biz = create_business(db_session)
        create_deal(db_session, biz["id"], stage="closing")
        create_deal(db_session, biz["id"], stage="lead")

        response = client.get("/api/deals/pipeline")
        data = response.json()
        stage_names = [s["stage"] for s in data["pipeline"]]
        assert stage_names.index("lead") < stage_names.index("closing")


class TestAdvanceDeal:
    def test_advance_stage(self, client, db_session):
        biz = create_business(db_session)
        deal = create_deal(db_session, biz["id"], stage="lead")

        response = client.patch(f"/api/deals/{deal['id']}/stage?stage=contacted")
        assert response.status_code == 200
        data = response.json()
        assert data["stage"] == "contacted"

    def test_invalid_stage(self, client, db_session):
        biz = create_business(db_session)
        deal = create_deal(db_session, biz["id"])

        response = client.patch(f"/api/deals/{deal['id']}/stage?stage=invalid")
        assert response.status_code == 400

    def test_close_won(self, client, db_session):
        biz = create_business(db_session)
        deal = create_deal(db_session, biz["id"], stage="closing")

        response = client.patch(f"/api/deals/{deal['id']}/stage?stage=closed_won")
        assert response.status_code == 200
        data = response.json()
        assert data["stage"] == "closed_won"
