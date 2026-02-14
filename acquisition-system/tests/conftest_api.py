"""API test fixtures - provides FastAPI TestClient with database session override."""

import os
import uuid
from datetime import datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Set test env vars before importing backend modules
os.environ.setdefault("DATABASE_URL", "postgresql://test:test@localhost:5432/test_acquisition")
os.environ.setdefault("ANTHROPIC_API_KEY", "sk-test-fake-key-for-testing")

from backend.api.app import create_app
from backend.api.deps import get_db


TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL",
    "postgresql://acquisition:devpassword@localhost:5432/test_acquisition",
)


@pytest.fixture(scope="session")
def test_engine():
    """Create test database and load schema."""
    # Connect to default db to create/reset test db
    admin_url = TEST_DATABASE_URL.rsplit("/", 1)[0] + "/acquisition"
    admin_engine = create_engine(admin_url, isolation_level="AUTOCOMMIT")
    with admin_engine.connect() as conn:
        # Terminate existing connections
        conn.execute(text(
            "SELECT pg_terminate_backend(pid) FROM pg_stat_activity "
            "WHERE datname = 'test_acquisition' AND pid <> pg_backend_pid()"
        ))
        conn.execute(text("DROP DATABASE IF EXISTS test_acquisition"))
        conn.execute(text("CREATE DATABASE test_acquisition"))
    admin_engine.dispose()

    # Load schema into test db
    engine = create_engine(TEST_DATABASE_URL)
    schema_path = os.path.join(os.path.dirname(__file__), "..", "database", "schema.sql")
    with open(schema_path) as f:
        schema_sql = f.read()
    with engine.connect() as conn:
        conn.execute(text(schema_sql))
        conn.commit()

    yield engine
    engine.dispose()


@pytest.fixture(scope="function")
def db_session(test_engine):
    """Per-test database session with rollback for isolation."""
    connection = test_engine.connect()
    transaction = connection.begin()
    Session = sessionmaker(bind=connection)
    session = Session()

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture(scope="function")
def client(db_session):
    """FastAPI test client with overridden DB dependency."""
    app = create_app()

    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as c:
        yield c
