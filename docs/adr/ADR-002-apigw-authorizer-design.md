# ADR-002: API Gateway Authorizer Configuration — Named Map, Type Split, and Capability vs Identity

## Status
Accepted

## Context
The `apigw` module must support two fundamentally different authorization mechanisms on the same API:

- **JWT** — API Gateway validates a bearer token against a Cognito or OIDC issuer. No Lambda is involved. The principal is a known, authenticated user.
- **REQUEST** — API Gateway delegates validation to a Lambda function. The principal may be anonymous; access is derived from possession of a capability token (e.g. a short-lived shoot token) with no OIDC issuer.

These two types share some fields (`type`, `name`, `identity_sources`) but diverge completely after that. JWT requires `jwt.audience` and `jwt.issuer`; REQUEST requires `authorizer_uri` and optionally `payload_format_version`, `enable_simple_responses`, and `result_ttl_seconds`.

Multiple routes may share one authorizer. Routes must reference authorizers by a stable logical name, not by position. REQUEST authorizer Lambdas are separate functions from the main integration Lambda and need their own `lambda:InvokeFunction` permissions granted to API Gateway.

The `authorization_type` field on a route (`"JWT"`, `"CUSTOM"`, or `"NONE"`) is derived from the authorizer type — requiring callers to specify it separately would be redundant and error-prone.

## Decision
Authorizers are declared as `authorizer_configs`, a `map(object(...))` keyed by a caller-chosen name. Routes reference authorizers by that key via an optional `authorizer` field (default `"NONE"`).

The module enforces the JWT/REQUEST split in `main.tf` using `dynamic` blocks:

```hcl
dynamic "jwt_configuration" {
  for_each = each.value.type == "JWT" ? [each.value.jwt] : []
  ...
}
authorizer_uri = each.value.type == "REQUEST" ? each.value.authorizer_uri : null
```

`authorization_type` on each route is derived automatically:

```hcl
authorization_type = (
  each.value.authorizer == "NONE" || each.value.authorizer == null ? "NONE" :
  aws_apigatewayv2_authorizer.this[each.value.authorizer].authorizer_type == "JWT" ? "JWT" :
  "CUSTOM"
)
```

REQUEST authorizer Lambdas receive invoke permissions via `extra_lambda_permissions`, a `map(string)` where the key becomes the `statement_id` suffix and the value is the function name. The `source_arn` uses `/*/*` (any stage, any route) because authorizer invocations are not tied to a specific route ARN.

REQUEST authorizer caching (`result_ttl_seconds`) defaults to `0`. For single-use capability tokens, caching must remain disabled — a cached response would allow token replay within the TTL window.

## Alternatives Considered

**List instead of map for `authorizer_configs`** — Routes reference authorizers by name, not by index. An index-based reference breaks whenever the list order changes. A named map provides stable references and allows the same key to thread through `authorizer_configs`, route `authorizer` fields, and `extra_lambda_permissions` `statement_id` suffixes.

**Require callers to set `authorization_type` on each route** — This is redundant: the type is fully determined by the referenced authorizer. Requiring it creates a surface for misconfiguration (e.g. `authorization_type = "JWT"` on a route that references a REQUEST authorizer).

**Replace REQUEST authorizers with JWT for capability tokens** — A capability token has no OIDC issuer. JWT validation requires an issuer URL and audience; there is nothing to validate against. JWT cannot substitute for REQUEST authorizers when the principal is anonymous and access is capability-based.

**Single `lambda_permissions` variable covering both the integration Lambda and authorizer Lambdas** — The integration Lambda always needs an invoke permission; it is handled unconditionally by `aws_lambda_permission.apigw`. Authorizer Lambdas are optional and variable in number. Separating them into `extra_lambda_permissions` keeps the unconditional grant stable and makes the optional grants explicit.

## Consequences
- Every `authorizer` value in `routes` must be `"NONE"` or a key present in `authorizer_configs`. An unknown key causes a Terraform error at plan time.
- JWT authorizers require `jwt` to be set; REQUEST authorizers require `authorizer_uri`. The module does not validate this at plan time — a missing field produces a null value and fails at apply time.
- An `extra_lambda_permissions` entry is required for every REQUEST authorizer Lambda. Omitting it causes a 403 when API Gateway invokes the authorizer.
- The identity vs. capability distinction is structural: JWT handles known users authenticated through an OIDC provider; REQUEST handles anonymous callers whose access is derived from token possession. The two mechanisms are not interchangeable and must coexist when both patterns appear on the same API.
