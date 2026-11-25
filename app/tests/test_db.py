import pytest
from sqlalchemy import create_engine
from sqlalchemy.exc import OperationalError

from tallybook import create_app, db


class FlakyMetadata:
    def __init__(self, failures):
        self.failures = failures
        self.calls = 0

    def create_all(self, _engine):
        self.calls += 1
        if self.calls <= self.failures:
            raise OperationalError("connect", {}, Exception("refused"))


def test_init_schema_retries_until_database_ready(monkeypatch):
    flaky = FlakyMetadata(failures=2)
    monkeypatch.setattr(db, "metadata", flaky)
    sleeps = []
    db.init_schema(object(), retries=5, delay=0.1, sleep=sleeps.append)
    assert flaky.calls == 3
    assert sleeps == [0.1, 0.1]


def test_init_schema_gives_up(monkeypatch):
    monkeypatch.setattr(db, "metadata", FlakyMetadata(failures=10))
    with pytest.raises(OperationalError):
        db.init_schema(object(), retries=2, delay=0, sleep=lambda _s: None)


def test_ping_false_when_unreachable(tmp_path):
    missing_dir = tmp_path / "nope" / "db.sqlite"
    engine = create_engine(f"sqlite:///{missing_dir}")
    assert db.ping(engine) is False


def test_create_app_builds_engine_from_env(tmp_path):
    url = f"sqlite:///{tmp_path / 'tally.db'}"
    app = create_app(settings_env={"DATABASE_URL": url, "DB_CONNECT_RETRIES": "1"})
    resp = app.test_client().get("/readyz")
    assert resp.status_code == 200
    app.extensions["engine"].dispose()


def test_wsgi_module_exposes_app(monkeypatch, tmp_path):
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{tmp_path / 'wsgi.db'}")
    import importlib

    import tallybook.wsgi as wsgi

    importlib.reload(wsgi)
    assert wsgi.app.name == "tallybook"
    wsgi.app.extensions["engine"].dispose()
