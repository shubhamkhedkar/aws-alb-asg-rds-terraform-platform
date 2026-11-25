"""Tallybook: a small expense ledger served by the web tier and backed by MySQL."""

from __future__ import annotations

import logging
import os

from flask import Flask, abort, jsonify, render_template, request
from sqlalchemy import Engine

from . import db
from .config import load_settings
from .validation import CATEGORIES, ValidationError, parse_entry

__version__ = "1.0.0"


def create_app(engine: Engine | None = None, settings_env: dict[str, str] | None = None) -> Flask:
    logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
    app = Flask(__name__)
    app.json.sort_keys = False

    if engine is None:
        settings = load_settings(settings_env)
        engine = db.make_engine(settings.database_url, settings.connect_args)
        db.init_schema(engine, settings.connect_retries, settings.connect_delay_seconds)
    else:
        db.init_schema(engine, retries=1)
    app.extensions["engine"] = engine

    @app.after_request
    def security_headers(response):
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "no-referrer")
        response.headers.setdefault(
            "Content-Security-Policy", "default-src 'self'; style-src 'self' 'unsafe-inline'"
        )
        return response

    @app.get("/healthz")
    def healthz():
        # Liveness for the ALB target group: the process is up and serving.
        return jsonify(status="ok", version=__version__)

    @app.get("/readyz")
    def readyz():
        # Readiness: the database tier is reachable from this instance.
        if db.ping(engine):
            return jsonify(status="ready", database="up")
        return jsonify(status="degraded", database="down"), 503

    @app.get("/api/entries")
    def list_entries():
        category = request.args.get("category")
        if category and category not in CATEGORIES:
            return jsonify(error="unknown category"), 400
        try:
            limit = min(max(int(request.args.get("limit", "100")), 1), 500)
        except ValueError:
            return jsonify(error="limit must be an integer"), 400
        return jsonify(entries=db.list_entries(engine, category, limit))

    @app.post("/api/entries")
    def create_entry():
        try:
            data = parse_entry(request.get_json(silent=True))
        except ValidationError as exc:
            return jsonify(error="validation failed", fields=exc.errors), 422
        return jsonify(db.add_entry(engine, **data)), 201

    @app.delete("/api/entries/<int:entry_id>")
    def remove_entry(entry_id: int):
        if not db.delete_entry(engine, entry_id):
            abort(404)
        return "", 204

    @app.get("/api/summary")
    def get_summary():
        return jsonify(db.summary(engine))

    @app.get("/")
    def index():
        return render_template(
            "index.html",
            entries=db.list_entries(engine, limit=20),
            totals=db.summary(engine),
            host=os.environ.get("HOSTNAME", "local"),
        )

    @app.errorhandler(404)
    def not_found(_err):
        return jsonify(error="not found"), 404

    return app
