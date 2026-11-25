"""Input validation for ledger entries."""

from __future__ import annotations

from datetime import date
from decimal import Decimal, InvalidOperation

CATEGORIES = ("rent", "groceries", "travel", "utilities", "health", "other")
MAX_AMOUNT = Decimal("9999999999.99")


class ValidationError(ValueError):
    def __init__(self, errors: dict[str, str]):
        super().__init__("invalid entry")
        self.errors = errors


def parse_entry(payload: object, today: date | None = None) -> dict:
    if not isinstance(payload, dict):
        raise ValidationError({"body": "expected a JSON object"})

    errors: dict[str, str] = {}

    description = payload.get("description")
    if not isinstance(description, str) or not description.strip():
        errors["description"] = "required"
    elif len(description.strip()) > 120:
        errors["description"] = "must be 120 characters or fewer"

    amount: Decimal | None = None
    raw_amount = payload.get("amount")
    if isinstance(raw_amount, bool) or raw_amount is None:
        errors["amount"] = "required"
    else:
        try:
            amount = Decimal(str(raw_amount))
        except InvalidOperation:
            errors["amount"] = "must be a number"
        else:
            if not amount.is_finite() or amount <= 0:
                errors["amount"] = "must be greater than zero"
            elif amount > MAX_AMOUNT:
                errors["amount"] = "is too large"
            elif amount.as_tuple().exponent < -2:
                errors["amount"] = "at most two decimal places"

    category = payload.get("category", "other")
    if category not in CATEGORIES:
        errors["category"] = f"must be one of: {', '.join(CATEGORIES)}"

    spent_on = today or date.today()
    raw_date = payload.get("spent_on")
    if raw_date is not None:
        try:
            spent_on = date.fromisoformat(str(raw_date))
        except ValueError:
            errors["spent_on"] = "must be an ISO date (YYYY-MM-DD)"

    if errors:
        raise ValidationError(errors)

    return {
        "description": description.strip(),
        "amount": amount,
        "category": category,
        "spent_on": spent_on,
    }
