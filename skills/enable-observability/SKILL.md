---
name: enable-observability
description: Habilita la observabilidad de MaaS en este cluster OpenShift AI (Tempo, OpenTelemetry, Cluster Observability Operator, Loki, MinIO + LokiStack y usage logging) para ver los tokens generados por API key. Usar cuando el usuario pida habilitar observabilidad o ver el uso de tokens.
---

# Enable MaaS observability

El stack se instala con el script del repo `rhoai-showroom`: clonalo si no existe, entra al directorio y ejecuta el script desde ahí. Al final verifica el estado y sale del repo con `cd ..`.

## 1. Clonar el repo

```sh
[ -d rhoai-showroom ] || git clone https://github.com/pkstaz/rhoai-showroom.git
cd rhoai-showroom
```

## 2. Stack de observabilidad

```sh
bash manifests/apply-maas-observability.sh
```

El script instala los operadores (Tempo, OpenTelemetry, Cluster Observability Operator, Loki), configura el monitoreo del DSCI (`monitoring`), enciende la telemetría del gateway (`maastenantconfig`), despliega MinIO + LokiStack y enciende `usageLogging`.

Puede tardar 10–20 minutos: espera cada CSV en `Succeeded`, LokiStack `Ready` y el patch de `usageLogging`. Muestra el progreso mientras corre y no lo interrumpas. Si se corta en un `oc wait` (`no matching resources found`), vuelve a lanzarlo: es idempotente.

## 3. Imagen de MinIO con el mirror de Red Hat

MinIO se ejecuta con las imágenes del mirror de Red Hat (`quay.io/rh-aiservices-bu`). Configura el deployment con la imagen del mirror:

```sh
oc -n redhat-ods-monitoring set image deploy/minio minio=quay.io/rh-aiservices-bu/minio:RELEASE.2025-09-07T16-13-09Z
oc -n redhat-ods-monitoring wait --for=condition=available deploy/minio --timeout=180s
```

El job `minio-create-bucket` crea el bucket `loki` que la LokiStack necesita para escribir. Se aplica con la imagen `quay.io/rh-aiservices-bu/mc:latest` (los jobs son inmutables):

```sh
oc get job minio-create-bucket -n redhat-ods-monitoring -o json \
  | jq 'del(.status, .metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.generation, .metadata.managedFields, .metadata.ownerReferences, .spec.selector, .spec.template.metadata.labels)' \
  | sed 's|quay.io/minio/mc:latest|quay.io/rh-aiservices-bu/mc:latest|' > /tmp/job2.yaml
oc delete job minio-create-bucket -n redhat-ods-monitoring --grace-period=0 --force
oc apply -f /tmp/job2.yaml
```

El job debe quedar `Complete`. Verifica el estado final con `oc get pods -n redhat-ods-monitoring | grep minio`.

## Verificación final

```sh
oc get csv -n openshift-tempo-operator | grep tempo
oc get csv -n openshift-opentelemetry-operator | grep opentelemetry
oc get csv -n openshift-cluster-observability-operator | grep cluster-observability
oc get csv -n openshift-operators-redhat | grep loki
oc get dsci default-dsci -o jsonpath='{.spec.monitoring.metrics}'; echo
oc get maastenantconfig default-tenant -n models-as-a-service -o jsonpath='{.spec.telemetry}'; echo
oc get lokistack usage -n redhat-ods-monitoring
oc get configs.maas.opendatahub.io default -o jsonpath='{.spec.usageLogging}'; echo
```

CSVs en `Succeeded`, `metrics` con replicas/storage, telemetría `enabled: true` y `usageLogging` `true`.

## Dónde ver los tokens

- RHOAI → *Observe & monitor* → *Dashboard* → Usage (tokens / requests por subscription)
- RHOAI → *Models as a Service* → API keys / uso por key

Reporta el estado de cada componente en una tabla, recuerda al usuario dónde ver el consumo de tokens y al terminar `cd ..` para salir del repo.
