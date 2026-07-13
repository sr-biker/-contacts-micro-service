# contacts-micro-service

Spring Boot + PostgreSQL contacts REST service (`/api/contacts`). One of two application workloads
running on the self-managed Kubernetes cluster provisioned by
[`infra`](https://github.com/sr-biker/infra) — see that repo's README for the overall architecture.

## Where this fits

- **Runtime**: deployed to the prod cluster as the Argo CD `Application` `contacts-micro-service`,
  which renders `helm/contacts-micro-service` directly from this repo (`values-prod.yaml`) — Argo CD
  auto-syncs and self-heals on every push to `main`. Owns the `/` path on the cluster's shared ingress
  controller (the only workload with a catch-all route; see `membership` for the path-scoped
  pattern other apps need to follow).
- **Data**: one database (`appdb`) on the shared PostgreSQL RDS instance provisioned by `infra`'s
  `modules/rds` — not its own database instance.
- **Image**: built (arm64, matching the cluster's Graviton nodes) and pushed to the `infra`-provisioned
  ECR repo `contacts-micro-service`. `prod/cicd` in `infra` builds this repo and publishes to ECR on
  push (see that repo's CLAUDE.md for what's still live in that pipeline vs. superseded by Argo CD).
- **Credentials**: no Kubernetes Secret and no CSI driver (this is a self-managed cluster — no
  IRSA/EKS Pod Identity for the CSI driver's AWS provider to use). The container's own entrypoint
  fetches `DB_USERNAME`/`DB_PASSWORD` from Secrets Manager at startup using the node's instance-profile
  credentials (`dbSecretFetch` in the Helm chart) — see `helm/contacts-micro-service/templates/deployment.yaml`.
- **Image pulls**: via `imagePullSecrets`, refreshed every 6h by an in-cluster CronJob (no
  `ecr-credential-provider` on kubelet — plain AL2023 EC2, not an EKS-optimized AMI).

## Local development

```bash
docker compose up --build
curl http://localhost:8080/api/contacts
```

`docker-compose.yml` runs the app against a local Postgres, no AWS calls. See
`infra/local/README.md` for running this inside a `kind` cluster instead (closer to prod's actual
deploy path: NodePort → ingress → Service → pod).

## Deploying a change

Push to `main`. Argo CD auto-syncs within its poll interval (or force it via
`argocd.argoproj.io/refresh=hard` annotation over SSM — see `infra`'s CLAUDE.md for the exact command
pattern, since there's no direct network path to the cluster). Bumping `helm/contacts-micro-service/values-prod.yaml`'s
`image.tag` after pushing a new image to ECR is what actually changes the deployed version.
