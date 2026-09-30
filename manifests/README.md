# Manifests

Kubernetes / OpenShift manifests and helper scripts for the workshop.
Run `oc apply` / scripts from the **repo root**.

| Path | Module |
|---|---|
| `llminferenceservice-qwen25-coder-7b-awq.yaml` | Qwen2.5-Coder-7B-AWQ en L4 con llm-d (module 3) |
| `opencode/` | OpenCode pod: namespace, build (ImageStream + BuildConfig), deploy, config (module 4) |
| `opencode/00-namespace.yaml` | Namespace `opencode` |
| `opencode/01-buildconfig.yaml` | ImageStream + BuildConfig (Dockerfile inline, registry interno) |
| `opencode/02-deploy.yaml` | SA + cluster-admin (workshop-only), Deployment, Service, Route |
| `opencode/03-configmap.yaml` | `opencode.jsonc` con el proveedor Qwen L4 (reemplazar `<MODEL_URL>`) |
| `maas/gatewayclass.yaml` | GatewayClass `openshift-default` (module 6, skill `configure-maas`) |
| `maas/kuadrant.yaml` | Instancia Kuadrant en `kuadrant-system` (module 6, skill `configure-maas`) |
| `maas/postgres.yaml` | MaaS Postgres + `maas-db-config` (module 6, skill `configure-maas`) |
| `maas/apply-gateway.sh` | MaaS Gateway (module 6, skill `configure-maas`) |
| `maas/maas-model-ref.yaml` | `MaaSModelRef` para publicar el modelo (module 7) |
| `maas/subscription.yaml` | Auth policy + subscription (module 7) |
| `observability/` | Tempo, OTEL, COO, Loki, MinIO (module 8, skill `enable-observability`) |
| `observability/apply-maas-observability.sh` | Observability stack installer |

Los skills de OpenCode (`configure-maas`, `enable-observability`) están en `skills/` (raíz del repo).
