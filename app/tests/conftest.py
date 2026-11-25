import pytest
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool

from tallybook import create_app


@pytest.fixture
def engine():
    # In-memory SQLite stands in for MySQL in unit tests; the compose smoke test covers MySQL.
    eng = create_engine(
        "sqlite+pysqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    yield eng
    eng.dispose()


@pytest.fixture
def client(engine):
    app = create_app(engine=engine)
    app.testing = True
    return app.test_client()
