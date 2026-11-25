#!/usr/bin/env bash
# Run every local quality gate. Nothing here needs AWS credentials or touches AWS.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"

step() { printf '\n==> %s\n' "$*"; }

step "terraform fmt"
terraform fmt -check -recursive infra

for dir in infra/terraform infra/bootstrap; do
  step "terraform init/validate: $dir"
  terraform -chdir="$dir" init -backend=false -input=false >/dev/null
  terraform -chdir="$dir" validate
done

step "terraform test (mocked AWS provider)"
terraform -chdir=infra/terraform test

step "tflint"
for dir in infra/terraform infra/bootstrap; do
  tflint --chdir="$dir" --config="$ROOT/.tflint.hcl" --init >/dev/null
  tflint --chdir="$dir" --config="$ROOT/.tflint.hcl" --recursive
done

step "checkov (terraform + Dockerfile)"
checkov --config-file .checkov.yaml -d infra --skip-path tests
checkov --config-file .checkov.yaml -f Dockerfile --framework dockerfile

step "trivy config scan"
trivy config --quiet --exit-code 1 --severity HIGH,CRITICAL --skip-dirs infra/terraform/tests .

step "app lint + tests"
(cd app && ruff check . && ruff format --check . && python -m pytest -q)

step "dependency audit"
pip-audit --strict -r app/requirements.txt

step "hadolint"
hadolint Dockerfile

step "shellcheck"
shellcheck scripts/*.sh
scripts/render-user-data.sh | shellcheck -s bash -

step "actionlint"
actionlint

step "compose config"
DB_PASSWORD=x DB_ROOT_PASSWORD=x docker compose config --quiet

step "gitleaks"
gitleaks dir --no-banner --redact .

printf '\nALL CHECKS PASSED\n'
