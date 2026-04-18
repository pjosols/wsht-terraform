# ADR-001: Conditional EventBridge Resources via `for_each` with a Local Set

## Status
Accepted

## Context
The monitoring module creates CloudWatch alarms unconditionally for every Lambda it monitors. It also optionally creates an EventBridge rule and target to invoke the Lambda on a schedule — useful for canary and health-check patterns where the Lambda must be called periodically to produce the metrics the alarms watch.

The resource must be created zero or one times depending on whether `schedule_expression` is set. Terraform offers two mechanisms for this: `count` and `for_each`.

The project conventions explicitly prohibit `count` for conditional resources and require `for_each` with a set or map instead.

## Decision
A local set is derived from `schedule_expression`:

```hcl
locals {
  schedule_set = var.schedule_expression != "" ? toset(["enabled"]) : toset([])
}
```

Both `aws_cloudwatch_event_rule.schedule` and `aws_cloudwatch_event_target.schedule` use `for_each = local.schedule_set`. When `schedule_expression` is empty the set is empty and no resources are created. When it is set the set contains one element (`"enabled"`) and one instance of each resource is created, addressed as `aws_cloudwatch_event_rule.schedule["enabled"]`.

`schedule_expression` should be set when the Lambda implements a canary or health-check pattern — i.e. when it must be invoked on a schedule to produce the metrics that the alarms monitor. Leave it empty for event-driven Lambdas whose invocations are driven by other triggers.

## Alternatives Considered

**`count = var.schedule_expression != "" ? 1 : 0`** — Works, but `count`-indexed resources are addressed by integer (`resource["0"]`). If the condition changes, Terraform may destroy and recreate resources rather than updating them in place, because the index shifts. `for_each` with a stable string key avoids this. The conventions ban `count` for conditional resources for this reason.

**A separate optional module** — Callers could invoke a dedicated `eventbridge_schedule` module only when needed. This adds caller complexity and splits related monitoring concerns across two modules. The single-module approach keeps all Lambda monitoring configuration in one place.

## Consequences
- Callers that do not need scheduling omit `schedule_expression` (or accept the default `""`); no EventBridge resources are created.
- Callers that need scheduling pass a valid EventBridge expression (e.g. `"rate(5 minutes)"`) and must also supply `lambda_function_arn`.
- The `"enabled"` key is a stable string; adding or removing scheduling never causes unrelated resource churn.
- Any future second optional resource group in this module should follow the same `local.*_set` pattern.
