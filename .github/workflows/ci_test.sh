#!/usr/bin/env bash
# Regression tests for .github/workflows/ci.yml
# Verifies: trigger configuration, pinned action versions, terraform version pinning,
# module matrix coverage (validate excludes cloudfront/waf; test includes all),
# job dependencies, and presence of fmt/validate/test steps.

set -uo pipefail

CI=".github/workflows/ci.yml"
[[ -f "$CI" ]] || { echo "Error: $CI not found"; exit 1; }
PASS=0; FAIL=0

assert() {
  local desc="$1"; shift
  if "$@" &>/dev/null; then
    echo "PASS: $desc"; PASS=$((PASS+1))
  else
    echo "FAIL: $desc"; FAIL=$((FAIL+1))
  fi
}

assert_not() {
  local desc="$1"; shift
  if ! "$@" &>/dev/null; then
    echo "PASS: $desc"; PASS=$((PASS+1))
  else
    echo "FAIL: $desc"; FAIL=$((FAIL+1))
  fi
}

# py DESCRIPTION PYTHON_EXPR — PYTHON_EXPR must raise on failure
py() {
  local desc="$1" expr="$2"
  assert "$desc" python3 - "$CI" <<EOF
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
on = doc[True]  # YAML 'on' parses as boolean True
jobs = doc['jobs']
$expr
EOF
}

# Triggers
py "push trigger on main"         "assert 'main' in on['push']['branches']"
py "pull_request trigger present" "assert 'pull_request' in on"

# Pinned action versions (no floating tags)
assert_not "checkout not unpinned"        grep -qE "actions/checkout@(main|master|latest)" "$CI"
assert_not "setup-terraform not unpinned" grep -qE "hashicorp/setup-terraform@(main|master|latest)" "$CI"
assert "checkout pinned to v4"            grep -q "actions/checkout@v4" "$CI"
assert "setup-terraform pinned to v3"     grep -q "hashicorp/setup-terraform@v3" "$CI"

# Terraform version pinned
py "terraform_version set" "
steps = jobs['validate']['steps']
tf = next(s for s in steps if s.get('with', {}).get('terraform_version'))
assert tf['with']['terraform_version']
"
assert_not "terraform_version not open range" grep -qE "terraform_version:.*[~^>]" "$CI"

# Validate matrix: 7 modules, no cloudfront/waf
for mod in acm apigw cognito kms lambda_container monitoring s3_bucket; do
  py "validate matrix includes $mod" "assert '$mod' in jobs['validate']['strategy']['matrix']['module']"
done
py "waf not in validate matrix"        "assert 'waf' not in jobs['validate']['strategy']['matrix']['module']"
py "cloudfront not in validate matrix" "assert 'cloudfront' not in jobs['validate']['strategy']['matrix']['module']"

# Test matrix: includes cloudfront and waf
py "waf in test matrix"        "assert 'waf' in jobs['test']['strategy']['matrix']['module']"
py "cloudfront in test matrix" "assert 'cloudfront' in jobs['test']['strategy']['matrix']['module']"

# Job dependencies
py "test job depends on validate" "
needs = jobs['test']['needs']
assert needs == 'validate' or 'validate' in needs
"
py "checkov job exists"          "assert 'checkov' in jobs"
py "checkov depends on validate" "
needs = jobs['checkov']['needs']
assert needs == 'validate' or 'validate' in needs
"
py "checkov uses .checkov.yaml" "
steps = jobs['checkov']['steps']
cfg = next(s['with']['config_file'] for s in steps if s.get('with', {}).get('config_file'))
assert cfg == '.checkov.yaml'
"

# Step presence
py "fmt -check step present" "
steps = jobs['validate']['steps']
assert any('fmt -check' in s.get('run', '') for s in steps)
"
py "terraform validate step" "
steps = jobs['validate']['steps']
assert any(s.get('run', '').strip() == 'terraform validate' for s in steps)
"
py "terraform test step" "
steps = jobs['test']['steps']
assert any(s.get('run', '').strip() == 'terraform test' for s in steps)
"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
