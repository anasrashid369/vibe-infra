# vibe-infra

Terraform for **Vibe**'s AWS infrastructure (Lambda BFF, API Gateway,
Secrets Manager, DynamoDB cache), written to be environment-agnostic —
the same configuration deploys to real AWS by swapping `use_localstack`
and providing real credentials.

No AWS account is required for local development. Everything runs
against [LocalStack](https://www.localstack.cloud/).

## Repos

| Repo | Purpose |
|---|---|
| [`vibe-client`](../vibe-client) | Flutter mobile app |
| [`vibe-bff`](../vibe-bff) | Node/TypeScript Lambda backend-for-frontend |
| `vibe-infra` (this repo) | Terraform + LocalStack infra |

## Structure

```
main.tf              # wires the four modules together
variables.tf
providers.tf          # conditional LocalStack endpoint block
modules/
  lambda_bff/          # the BFF Lambda function + IAM role
  api_gateway/          # HTTP API + routes + Lambda permission
  secrets/               # Secrets Manager (provider API keys)
  dynamodb_cache/         # optional response cache / audit log
environments/
  local.tfvars           # LocalStack
  prod.tfvars             # placeholder, unused until a real AWS account exists
```

## Local workflow

```bash
docker compose up -d localstack
terraform init
terraform apply -var-file="environments/local.tfvars"
```

This stands up the full BFF stack (Lambda, API Gateway, Secrets Manager,
DynamoDB) against LocalStack from a clean checkout — see the MVP
acceptance criteria in the project spec.

Before applying, build the BFF deployment package expected by
`modules/lambda_bff` (`lambda_zip_path`, default
`../vibe-bff/dist/bundle.zip`):

```bash
cd ../vibe-bff
npm run build
# TODO(Phase 1): add a bundling step (esbuild/zip) that produces dist/bundle.zip
```

## CI

`.github/workflows/infra-ci.yml` runs `terraform fmt -check`,
`terraform validate`, and `terraform plan` against a LocalStack service
container on every push/PR — proof the IaC is mechanically verified, not
just written and forgotten.

## Real AWS (Phase 5, stretch)

Swap `environments/prod.tfvars` (`use_localstack = false`), supply real
`aws_access_key`/`aws_secret_key` (via CI secrets or env vars — never
committed), and apply:

```bash
terraform apply -var-file="environments/prod.tfvars"
```

## Status

Scaffold only — Phase 0. Modules define real resources but have not been
applied against LocalStack yet; that's the first task of Phase 1.
