---
name: configure-maas
description: Configura Models as a Service (MaaS) en este cluster OpenShift AI — postgres, gateway MaaS y aigateway.modelsAsAService en el DataScienceCluster. Usar cuando el usuario pida habilitar o configurar MaaS.
---

# Configure MaaS

Ejecuta los pasos en orden desde la raíz del repo de este workshop (busca el directorio que contenga `manifests/maas/`; típico `~/opencode-maas-observability-workshop`). Verifica cada paso antes de seguir; si un paso falla, detente y reporta el error. Al final reporta el estado de todo en una tabla.

## 1. Postgres

```sh
oc apply -f manifests/maas/postgres.yaml
oc wait --for=condition=available deployment/maas-postgres -n redhat-ai-gateway-infra --timeout=300s
```

Debe quedar `deployment/maas-postgres` `Available`.

## 2. Gateway MaaS

```sh
bash manifests/maas/apply-gateway.sh
```

Debe imprimir `Gateway ready: https://maas.<cluster-domain>`. Verifica con `oc get gateway maas-default-gateway -n openshift-ingress` (`Programmed = True`).

## 3. Encender MaaS en el DataScienceCluster

```sh
oc patch dsc default-dsc --type merge -p '{"spec":{"components":{"aigateway":{"managementState":"Managed","modelsAsAService":{"managementState":"Managed"}}}}}'
```

Espera los pods `maas-api` y `maas-controller` en `Running` (namespace `redhat-ods-applications`, timeout 600s):

```sh
oc get pods -n redhat-ods-applications | grep -i maas
```

## Verificación final

- `oc get pods -n redhat-ai-gateway-infra` (Postgres `Running`)
- `oc get gateway maas-default-gateway -n openshift-ingress` (`Programmed = True`)
- `oc get pods -n redhat-ods-applications | grep -i maas` (`maas-api`, `maas-controller` `Running`)
- `oc get dsc default-dsc` (`Ready`)

Nota: estos comandos tienen efecto real en el cluster. Muestra el plan antes de ejecutar cada paso.
