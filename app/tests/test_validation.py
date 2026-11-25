from datetime import date
from decimal import Decimal

import pytest

from tallybook.validation import ValidationError, parse_entry

TODAY = date(2026, 11, 25)


def test_valid_entry_defaults():
    data = parse_entry({"description": "  Milk  ", "amount": "60"}, today=TODAY)
    assert data == {
        "description": "Milk",
        "amount": Decimal("60"),
        "category": "other",
        "spent_on": TODAY,
    }


def test_accepts_numeric_amount_and_explicit_date():
    data = parse_entry(
        {"description": "Bus", "amount": 25.5, "category": "travel", "spent_on": "2026-10-02"}
    )
    assert data["amount"] == Decimal("25.5")
    assert data["spent_on"] == date(2026, 10, 2)


@pytest.mark.parametrize(
    ("payload", "field", "message"),
    [
        ({"amount": "1"}, "description", "required"),
        ({"description": "x" * 121, "amount": "1"}, "description", "120 characters"),
        ({"description": "a"}, "amount", "required"),
        ({"description": "a", "amount": True}, "amount", "required"),
        ({"description": "a", "amount": "abc"}, "amount", "must be a number"),
        ({"description": "a", "amount": "0"}, "amount", "greater than zero"),
        ({"description": "a", "amount": "NaN"}, "amount", "greater than zero"),
        ({"description": "a", "amount": "1e12"}, "amount", "too large"),
        ({"description": "a", "amount": "1.005"}, "amount", "two decimal places"),
        ({"description": "a", "amount": "1", "category": "yacht"}, "category", "must be one of"),
        ({"description": "a", "amount": "1", "spent_on": "25/11/2026"}, "spent_on", "ISO date"),
    ],
)
def test_rejects_bad_fields(payload, field, message):
    with pytest.raises(ValidationError) as exc:
        parse_entry(payload, today=TODAY)
    assert message in exc.value.errors[field]


def test_rejects_non_object():
    with pytest.raises(ValidationError) as exc:
        parse_entry(["not", "an", "object"])
    assert exc.value.errors == {"body": "expected a JSON object"}
