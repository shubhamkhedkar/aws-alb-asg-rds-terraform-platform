"""Runtime configuration read from environment variables."""

from __future__ import annotations

import os
from dataclasses import dataclass
from urllib.parse import quote_plus


@dataclass(frozen=True)
class Settings:
    database_url: str
    connect_args: dict
    connect_retries: int = 10
    connect_delay_seconds: float = 2.0


def database_url_from_env(env: dict[str, str] | None = None) -> tuple[str, dict]:
    """Build a SQLAlchemy URL and driver arguments.

    DATABASE_URL wins when set (used by tests). Otherwise the DB_* variables are
    combined into a PyMySQL URL; on AWS, DB_SSL_CA points at the RDS CA bundle
    because the parameter group enforces TLS.
    """
    env = dict(os.environ if env is None else env)

    if env.get("DATABASE_URL"):
        return env["DATABASE_URL"], {}

    missing = [k for k in ("DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD") if not env.get(k)]
    if missing:
        raise RuntimeError(f"missing database settings: {', '.join(missing)}")

    user = quote_plus(env["DB_USER"])
    password = quote_plus(env["DB_PASSWORD"])
    port = int(env.get("DB_PORT", "3306"))
    url = f"mysql+pymysql://{user}:{password}@{env['DB_HOST']}:{port}/{env['DB_NAME']}?charset=utf8mb4"

    connect_args: dict = {}
    if env.get("DB_SSL_CA"):
        connect_args["ssl"] = {"ca": env["DB_SSL_CA"]}
    return url, connect_args


def load_settings(env: dict[str, str] | None = None) -> Settings:
    source = os.environ if env is None else env
    url, connect_args = database_url_from_env(env)
    return Settings(
        database_url=url,
        connect_args=connect_args,
        connect_retries=int(source.get("DB_CONNECT_RETRIES", "10")),
        connect_delay_seconds=float(source.get("DB_CONNECT_DELAY", "2")),
    )
