#!/usr/bin/env bash
# Regression tests for .github/workflows/ci.yml
set -uo pipefail

CI=".github/workflows/ci.yml"
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

# Triggers
assert "push trigger on main"          grep -q "branches: \[main\]" "$CI"
assert "pull_request trigger present"  grep -q "pull_request:" "$CI"

# Pinned action versions (no floating tags)
assert_not "checkout not unpinned"     grep -qE "actions/checkout@(main|master|latest)" "$CI"
assert_not "setup-terraform not unpinned" grep -qE "hashicorp/setup-terraform@(main|master|latest)" "$CI"
assert "checkout pinned to v4"         grep -q "actions/checkout@v4" "$CI"
assert "setup-terraform pinned to v3"  grep -q "hashicorp/setup-terraform@v3" "$CI"

# Terraform version pinned
assert "terraform_version set"         grep -q "terraform_version:" "$CI"
assert_not "terraform_version not open range" grep -qE "terraform_version:.*[~^>]" "$CI"

# Matrix covers all 9 modules
for mod in acm apigw cloudfront cognito kms lambda_container monitoring s3_bucket waf; do
  assert "matrix includes $mod"        grep -q "$mod" "$CI"
done

# Job dependency: test needs validate
assert "test job depends on validate"  grep -q "needs: validate" "$CI"

# fmt check present
assert "fmt -check step present"       grep -q "terraform fmt -check" "$CI"

# validate step present
assert "terraform validate step"       grep -q "terraform validate" "$CI"

# test step present
assert "terraform test step"           grep -q "terraform test" "$CI"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
