"""Data access for ledger entries (SQLAlchemy Core, MySQL in production)."""

from __future__ import annotations

import logging
import time
from collections.abc import Callable
from datetime import UTC, date, datetime
from decimal import Decimal

from sqlalchemy import (
    Column,
    Date,
    DateTime,
    Engine,
    Integer,
    MetaData,
    Numeric,
    String,
    Table,
    create_engine,
    delete,
    func,
    insert,
    select,
    text,
)
from sqlalchemy.exc import OperationalError

log = logging.getLogger(__name__)

metadata = MetaData()

entries = Table(
    "entries",
    metadata,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column("description", String(120), nullable=False),
    Column("amount", Numeric(12, 2), nullable=False),
    Column("category", String(32), nullable=False, index=True),
    Column("spent_on", Date, nullable=False),
    Column(
        "created_at",
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    ),
)


def make_engine(url: str, connect_args: dict | None = None) -> Engine:
    return create_engine(url, connect_args=connect_args or {}, pool_pre_ping=True, future=True)


def init_schema(
    engine: Engine,
    retries: int = 10,
    delay: float = 2.0,
    sleep: Callable[[float], None] = time.sleep,
) -> None:
    """Create tables, waiting for the database to accept connections first."""
    for attempt in range(1, retries + 1):
        try:
            metadata.create_all(engine)
            return
        except OperationalError:
            if attempt == retries:
                raise
            log.warning("database not ready (attempt %s/%s), retrying", attempt, retries)
            sleep(delay)


def ping(engine: Engine) -> bool:
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except OperationalError:
        return False


def _row_to_dict(row) -> dict:
    return {
        "id": row.id,
        "description": row.description,
        "amount": f"{Decimal(row.amount):.2f}",
        "category": row.category,
        "spent_on": row.spent_on.isoformat(),
    }


def add_entry(
    engine: Engine, description: str, amount: Decimal, category: str, spent_on: date
) -> dict:
    with engine.begin() as conn:
        result = conn.execute(
            insert(entries).values(
                description=description, amount=amount, category=category, spent_on=spent_on
            )
        )
        new_id = result.inserted_primary_key[0]
        row = conn.execute(select(entries).where(entries.c.id == new_id)).one()
    return _row_to_dict(row)


def list_entries(engine: Engine, category: str | None = None, limit: int = 100) -> list[dict]:
    query = select(entries).order_by(entries.c.spent_on.desc(), entries.c.id.desc()).limit(limit)
    if category:
        query = query.where(entries.c.category == category)
    with engine.connect() as conn:
        return [_row_to_dict(r) for r in conn.execute(query)]


def delete_entry(engine: Engine, entry_id: int) -> bool:
    with engine.begin() as conn:
        result = conn.execute(delete(entries).where(entries.c.id == entry_id))
    return result.rowcount > 0


def summary(engine: Engine) -> dict:
    query = (
        select(entries.c.category, func.sum(entries.c.amount).label("total"))
        .group_by(entries.c.category)
        .order_by(entries.c.category)
    )
    with engine.connect() as conn:
        rows = conn.execute(query).all()
    by_category = {r.category: Decimal(r.total) for r in rows}
    grand = sum(by_category.values(), Decimal("0"))
    return {
        "by_category": {k: f"{v:.2f}" for k, v in by_category.items()},
        "total": f"{grand:.2f}",
    }
