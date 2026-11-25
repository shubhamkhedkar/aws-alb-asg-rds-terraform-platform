#!/usr/bin/env bash
# Build and start the local two-tier stack, exercise it through the proxy, then tear it down.
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="tallybook-smoke"
ENV_FILE="$(mktemp)"
PORT="${SMOKE_PORT:-18088}"
trap 'docker compose -p "$PROJECT" --env-file "$ENV_FILE" down -v --remove-orphans >/dev/null 2>&1 || true; rm -f "$ENV_FILE"' EXIT

# Throwaway credentials generated per run; never written into the repository.
{
  echo "DB_PASSWORD=$(openssl rand -hex 16)"
  echo "DB_ROOT_PASSWORD=$(openssl rand -hex 16)"
  echo "PROXY_PORT=${PORT}"
} >"$ENV_FILE"

compose() { docker compose -p "$PROJECT" --env-file "$ENV_FILE" "$@"; }

echo "==> building and starting stack"
compose up -d --build --wait --wait-timeout 240

BASE="http://127.0.0.1:${PORT}"
fail() { echo "FAIL: $*" >&2; compose logs --tail 50 >&2; exit 1; }

echo "==> liveness and readiness through the proxy"
curl -fsS "$BASE/healthz" | grep -q '"status":"ok"' || fail "healthz"
curl -fsS "$BASE/readyz" | grep -q '"database":"up"' || fail "readyz"

echo "==> write path hits MySQL"
curl -fsS -X POST "$BASE/api/entries" -H 'Content-Type: application/json' \
  -d '{"description":"Smoke test groceries","amount":"249.99","category":"groceries","spent_on":"2026-11-25"}' \
  | grep -q '"amount":"249.99"' || fail "create entry"
curl -fsS -X POST "$BASE/api/entries" -H 'Content-Type: application/json' \
  -d '{"description":"Smoke test cab","amount":"180","category":"travel"}' >/dev/null || fail "create second entry"
status=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/api/entries" \
  -H 'Content-Type: application/json' -d '{"description":"","amount":-1}')
[[ "$status" == "422" ]] || fail "validation returned $status"

echo "==> read path and aggregation"
curl -fsS "$BASE/api/summary" | grep -q '"total":"429.99"' || fail "summary total"
curl -fsS "$BASE/" | grep -q 'Smoke test groceries' || fail "index page"

echo "==> load is spread over both web replicas"
upstreams=$(for _ in $(seq 1 12); do
  curl -fsS -o /dev/null -D - "$BASE/healthz" | tr -d '\r' | awk -F': ' 'tolower($1)=="x-upstream"{print $2}'
done | sort -u | wc -l)
[[ "$upstreams" -ge 2 ]] || fail "expected 2 upstreams, saw $upstreams"

echo "==> data survives a web tier restart (state lives only in the DB tier)"
compose restart web >/dev/null
compose up -d --wait --wait-timeout 120 >/dev/null
curl -fsS "$BASE/api/summary" | grep -q '"total":"429.99"' || fail "data lost after restart"

echo "==> database is not reachable from the proxy tier"
# Positive control first, so a missing nc binary cannot make the negative check pass.
compose exec -T proxy sh -c 'nc -z -w 3 web 8080' >/dev/null 2>&1 || fail "proxy cannot reach web (nc control failed)"
if compose exec -T proxy sh -c 'nc -z -w 3 db 3306' >/dev/null 2>&1; then
  fail "proxy can reach the database"
fi

echo "SMOKE TEST PASSED"
