"""
tests/test_app.py
Unit tests – run by CodeBuild pre_build phase.
"""

import json
import pytest
from app import create_app


@pytest.fixture
def client():
    app = create_app()
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


# ── /health ────────────────────────────────────────────────────────────────
def test_health_returns_200(client):
    res = client.get("/health")
    assert res.status_code == 200


def test_health_json_body(client):
    res  = client.get("/health")
    data = json.loads(res.data)
    assert data["status"] == "healthy"
    assert "service" in data


# ── /api/time ──────────────────────────────────────────────────────────────
def test_api_time_returns_200(client):
    res = client.get("/api/time")
    assert res.status_code == 200


def test_api_time_keys(client):
    res  = client.get("/api/time")
    data = json.loads(res.data)
    for key in ("time", "date", "timestamp", "timezone"):
        assert key in data, f"Missing key: {key}"


def test_api_time_format(client):
    res  = client.get("/api/time")
    data = json.loads(res.data)
    # HH:MM:SS
    parts = data["time"].split(":")
    assert len(parts) == 3
    assert all(len(p) == 2 for p in parts)


# ── /version ───────────────────────────────────────────────────────────────
def test_version_returns_200(client):
    res = client.get("/version")
    assert res.status_code == 200


def test_version_keys(client):
    res  = client.get("/version")
    data = json.loads(res.data)
    for key in ("version", "build_id", "commit", "environment"):
        assert key in data, f"Missing key: {key}"


# ── / (index) ──────────────────────────────────────────────────────────────
def test_index_returns_200(client):
    res = client.get("/")
    assert res.status_code == 200
    assert b"AWS" in res.data
