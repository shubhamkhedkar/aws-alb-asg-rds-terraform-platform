import pytest


def add(client, **overrides):
    body = {"description": "Weekly vegetables", "amount": "450.50", "category": "groceries"}
    body.update(overrides)
    return client.post("/api/entries", json=body)


def test_healthz_reports_version(client):
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok", "version": "1.0.0"}


def test_readyz_when_database_up(client):
    resp = client.get("/readyz")
    assert resp.status_code == 200
    assert resp.get_json()["database"] == "up"


def test_readyz_when_database_down(client, monkeypatch):
    monkeypatch.setattr("tallybook.db.ping", lambda _engine: False)
    resp = client.get("/readyz")
    assert resp.status_code == 503
    assert resp.get_json()["status"] == "degraded"


def test_security_headers_present(client):
    resp = client.get("/healthz")
    assert resp.headers["X-Content-Type-Options"] == "nosniff"
    assert resp.headers["X-Frame-Options"] == "DENY"
    assert "default-src 'self'" in resp.headers["Content-Security-Policy"]


def test_create_and_list_entry(client):
    resp = add(client, spent_on="2026-11-20")
    assert resp.status_code == 201
    created = resp.get_json()
    assert created["amount"] == "450.50"
    assert created["spent_on"] == "2026-11-20"

    listed = client.get("/api/entries").get_json()["entries"]
    assert [e["id"] for e in listed] == [created["id"]]


def test_list_orders_newest_first_and_filters(client):
    add(client, description="Rent", amount=15000, category="rent", spent_on="2026-11-01")
    add(client, description="Train", amount="320", category="travel", spent_on="2026-11-15")
    all_entries = client.get("/api/entries").get_json()["entries"]
    assert [e["description"] for e in all_entries] == ["Train", "Rent"]

    travel = client.get("/api/entries?category=travel").get_json()["entries"]
    assert [e["description"] for e in travel] == ["Train"]


def test_list_limit_is_clamped(client):
    for i in range(3):
        add(client, description=f"item {i}")
    assert len(client.get("/api/entries?limit=2").get_json()["entries"]) == 2
    assert len(client.get("/api/entries?limit=0").get_json()["entries"]) == 1


@pytest.mark.parametrize(
    ("query", "message"),
    [("category=yachts", "unknown category"), ("limit=many", "limit must be an integer")],
)
def test_list_rejects_bad_query(client, query, message):
    resp = client.get(f"/api/entries?{query}")
    assert resp.status_code == 400
    assert resp.get_json()["error"] == message


def test_create_rejects_invalid_payload(client):
    resp = client.post("/api/entries", json={"description": "", "amount": -5})
    assert resp.status_code == 422
    fields = resp.get_json()["fields"]
    assert set(fields) == {"description", "amount"}


def test_create_rejects_non_json(client):
    resp = client.post("/api/entries", data="not json", content_type="text/plain")
    assert resp.status_code == 422
    assert "body" in resp.get_json()["fields"]


def test_delete_entry(client):
    entry_id = add(client).get_json()["id"]
    assert client.delete(f"/api/entries/{entry_id}").status_code == 204
    assert client.delete(f"/api/entries/{entry_id}").status_code == 404
    assert client.get("/api/entries").get_json()["entries"] == []


def test_summary_totals_by_category(client):
    add(client, amount="100.25", category="groceries")
    add(client, amount="99.75", category="groceries")
    add(client, amount="500", category="utilities")
    data = client.get("/api/summary").get_json()
    assert data == {
        "by_category": {"groceries": "200.00", "utilities": "500.00"},
        "total": "700.00",
    }


def test_summary_empty(client):
    assert client.get("/api/summary").get_json() == {"by_category": {}, "total": "0.00"}


def test_index_renders_entries(client):
    add(client, description="Electricity bill", category="utilities", amount="1200")
    resp = client.get("/")
    assert resp.status_code == 200
    html = resp.get_data(as_text=True)
    assert "Electricity bill" in html
    assert "1200.00" in html


def test_index_escapes_user_input(client):
    add(client, description="<script>alert(1)</script>")
    html = client.get("/").get_data(as_text=True)
    assert "<script>alert(1)</script>" not in html
    assert "&lt;script&gt;" in html


def test_unknown_route_returns_json_404(client):
    resp = client.get("/nope")
    assert resp.status_code == 404
    assert resp.get_json() == {"error": "not found"}
