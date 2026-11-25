import pytest

from tallybook.config import database_url_from_env, load_settings

BASE = {
    "DB_HOST": "db.internal",
    "DB_NAME": "tallybook",
    "DB_USER": "app",
    "DB_PASSWORD": "p@ss/w:rd",
}


def test_database_url_override_wins():
    url, args = database_url_from_env({"DATABASE_URL": "sqlite://", **BASE})
    assert url == "sqlite://"
    assert args == {}


def test_builds_mysql_url_and_escapes_password():
    url, args = database_url_from_env(BASE)
    assert url == "mysql+pymysql://app:p%40ss%2Fw%3Ard@db.internal:3306/tallybook?charset=utf8mb4"
    assert args == {}


def test_tls_ca_enables_ssl_args():
    _url, args = database_url_from_env(
        {**BASE, "DB_PORT": "3307", "DB_SSL_CA": "/certs/rds-ca.pem"}
    )
    assert args == {"ssl": {"ca": "/certs/rds-ca.pem"}}
    assert ":3307/" in _url


def test_missing_settings_are_reported():
    with pytest.raises(RuntimeError, match="DB_HOST, DB_PASSWORD"):
        database_url_from_env({"DB_NAME": "x", "DB_USER": "y"})


def test_load_settings_reads_retry_knobs():
    settings = load_settings({**BASE, "DB_CONNECT_RETRIES": "3", "DB_CONNECT_DELAY": "0.5"})
    assert settings.connect_retries == 3
    assert settings.connect_delay_seconds == 0.5


def test_load_settings_from_process_env(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "sqlite://")
    settings = load_settings()
    assert settings.database_url == "sqlite://"
    assert settings.connect_retries == 10
