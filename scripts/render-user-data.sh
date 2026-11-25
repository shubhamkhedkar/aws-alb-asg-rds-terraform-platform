#!/usr/bin/env bash
# Render the web tier user-data template with sample values so it can be linted
# (shellcheck) or reviewed. Prints the rendered script to stdout.
set -euo pipefail

TEMPLATE="$(cd "$(dirname "$0")/.." && pwd)/infra/terraform/modules/web/templates/user-data.sh.tftpl"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

expr="templatefile(\"${TEMPLATE}\", {
  region        = \"ap-south-1\",
  app_image     = \"111122223333.dkr.ecr.ap-south-1.amazonaws.com/tally-prod/tallybook:1.0.0\",
  app_port      = 8080,
  db_host       = \"tally-prod.example.ap-south-1.rds.amazonaws.com\",
  db_port       = 3306,
  db_name       = \"tallybook\",
  db_secret_arn = \"arn:aws:secretsmanager:ap-south-1:111122223333:secret:rds-db-example\"
})"

# terraform console reads one line per expression, so fold newlines first.
# It wraps multi-line strings in <<EOT ... EOT; strip those two lines.
(cd "$WORKDIR" && tr "\n" " " <<<"$expr" | terraform console) | sed '1d;$d'
