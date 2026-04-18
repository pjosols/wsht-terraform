# ADR-006: WAF — Rule Priority Layout and Managed Rule Merging

## Status
Accepted

## Context
The `waf` module produces a WAFv2 Web ACL for CloudFront distributions. Every ACL must include a security baseline — at minimum a rate-limit rule and the two AWS managed rule groups that cover common web exploits and known bad inputs. These must be present unconditionally; a misconfiguration that omits them would ship an unprotected endpoint.

Callers also need to add rules beyond the baseline: additional AWS managed rule groups (e.g. SQLi, IP reputation) and custom rules (geo blocks, IP set matches, rate-based rules with scope-down). These caller-supplied rules must not collide in priority with the baseline rules, and WAFv2 rejects duplicate priorities at apply time.

A caller may also need to override a default managed rule — for example, to pin a specific version of `AWSManagedRulesCommonRuleSet`. The override mechanism must not require forking the module.

## Decision
The module uses a fixed priority layout:

| Priority | Rule |
|---|---|
| 0 | `rate-limit` (always present, hardcoded) |
| 1 | `AWSManagedRulesCommonRuleSet` (always present) |
| 2 | `AWSManagedRulesKnownBadInputsRuleSet` (always present) |
| 10+ | `additional_managed_rules` (caller-supplied) |
| Any | `custom_rules` (caller-supplied, caller-controlled priority) |

The gap between 2 and 10 reserves space for future default managed rules without requiring callers to renumber their `additional_managed_rules` entries.

The two default managed rules are defined as a local map keyed by rule name. Caller-supplied `additional_managed_rules` are converted to a map with the same key. `merge()` combines them:

```hcl
all_managed_rules = merge(local.default_managed_rules, local.extra_managed_rules)
```

If a caller's entry has the same name as a default rule, the caller's entry wins. This allows overriding a default rule (e.g. to pin a version) without forking the module.

`additional_managed_rules` is for AWS-managed rule groups; the module handles the `managed_rule_group_statement` block. `custom_rules` is for rules with custom statements; each entry is passed verbatim into the `rule` dynamic block, including `action`/`override_action` and `statement`.

There is no variable to disable the two default managed rules or the rate-limit rule.

## Alternatives Considered

**Allow callers to disable default managed rules** — A variable like `enable_common_rule_set = false` would let callers ship an unprotected endpoint by accident. The unconditional baseline is the point of the module. Callers who genuinely need to remove a rule can override it via `additional_managed_rules` (same-name entry wins) or fork the module.

**Single `rules` variable for all rules** — Callers would supply the full rule list, including the baseline. This removes the safety guarantee — a caller who forgets the baseline ships without it. Separating baseline from caller-supplied rules keeps the guarantee unconditional.

**Priority as a module-assigned sequence** — The module could assign priorities automatically (e.g. baseline at 0–9, then sequential from 10). This would prevent collisions but remove caller control over relative ordering among their own rules. WAFv2 evaluates rules in priority order; callers sometimes need to control which of their rules fires first.

**`additional_managed_rules` and `custom_rules` as a single variable** — Managed rule groups and custom rules have different required fields (`managed_rule_group_statement` vs. a full `statement` block). A single variable would require callers to construct the full rule object for managed groups, duplicating the boilerplate the module currently handles.

## Consequences
- Priorities 0–9 are reserved. Callers must use 10+ for `additional_managed_rules` and must avoid 0–9 in `custom_rules`.
- `additional_managed_rules` entries must have unique `name` values. Duplicate names silently overwrite each other (`merge` behavior). The last entry with a given name wins.
- `additional_managed_rules` and `custom_rules` priorities must not collide with each other. WAFv2 rejects duplicate priorities at apply time.
- A caller can override a default managed rule by supplying an `additional_managed_rules` entry with the same name. The caller's entry replaces the default entirely, including its priority — the caller must assign a priority that does not collide with the other default rules.
