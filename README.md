# vibe-infra

Terraform for **Vibe**'s AWS infrastructure (Lambda BFF, API Gateway,
Secrets Manager, DynamoDB), written to be environment-agnostic — the same
configuration deploys to real AWS by swapping `use_localstack` and
providing real credentials. **This project runs LocalStack-only** — no
paid AWS account required or used.

## Structure

main.tf, variables.tf, providers.tf
modules/
lambda_bff/ # Lambda + IAM role/policy
api_gateway/ # REST API v1 ({proxy+} + ANY method) -- NOT HTTP API v2,
# which requires a LocalStack license tier we don't have
secrets/ # Secrets Manager (provider API keys)
dynamodb_cache/ # metrics counters + response cache
environments/
local.tfvars # LocalStack (the only environment actually used)
prod.tfvars # placeholder, unused, kept for reference only


## Local workflow

**Always start LocalStack via the CLI, not `docker compose`** — the
Pro image in `docker-compose.yml` needs a `LOCALSTACK_AUTH_TOKEN` env var
we don't have configured; the CLI handles free-tier license activation
automatically.

```bash
localstack start -d
# wait ~15s
terraform init
terraform apply -var-file="environments/local.tfvars"
terraform output api_endpoint
```

**LocalStack does not persist state across container restarts** in our
setup. If you restart Docker/your machine, `terraform apply` will recreate
everything and the REST API ID **will change** — always confirm the current
ID with `terraform output api_endpoint` before pointing the client at it,
and re-run `vibe-bff/scripts/update-secret.ts` to repopulate real API keys
(the secret resets to placeholders on recreation).

## CI

`.github/workflows/infra-ci.yml` runs `terraform fmt/validate/plan` against
a LocalStack service container on every push/PR.

## Status
All 15 resources deploy cleanly and have been verified end-to-end multiple
times across development sessions, including under real provider outages
(Gemini 503s triggering live failover to Groq).
