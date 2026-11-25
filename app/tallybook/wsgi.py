"""Gunicorn entry point: gunicorn tallybook.wsgi:app"""

from . import create_app

app = create_app()
