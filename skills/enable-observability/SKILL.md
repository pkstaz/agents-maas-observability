---
name: enable-observability
description: Habilita la observabilidad de MaaS en este cluster OpenShift AI (Tempo, OTEL, Cluster Observability Operator, Loki y usage logging) para ver los tokens generados por API key. Usar cuando el usuario pida habilitar observabilidad o ver el uso de tokens.
---

# Enable MaaS observability

Ejecuta desde la raíz del repo de este workshop (busca el directorio que contenga `manifests/observability/`; típico `~/opencode-maas-observability-workshop`).

## 1. Stack de observabilidad

```sh
bash manifests/observability/apply-maas-observability.sh
```

El script instala los operadores (Tempo, OpenTelemetry, Cluster Observability Operator, Loki), configura el monitoreo del DSCI, enciende la telemetría del gateway MaaS (`maastenantconfig`), despliega MinIO + LokiStack y enciende `usageLogging`.

Puede tardar ~10 minutos: el script espera cada CSV en `Succeeded`. Muestra el progreso mientras corre y no lo interrumpas.

## 2. Verificación final

```sh
oc get configs.maas.opendatahub.io default -o jsonpath='{.spec.usageLogging}'
oc get lokistack usage -n redhat-ods-monitoring
oc get persesdashboard -n redhat-ods-monitoring
```

`usageLogging` debe ser `true`.

## Dónde ver los tokens

- RHOAI → *Observe & monitor* → *Dashboards* (dashboards de uso/usage)
- RHOAI → *Models as a Service* → API keys / uso por key

Reporta el estado de cada componente en una tabla y recuerda al usuario dónde ver el consumo de tokens.
