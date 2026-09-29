---
name: configure-maas
description: Configura Models as a Service (MaaS) en este cluster OpenShift AI — GatewayClass openshift-default, instancia Kuadrant, postgres, gateway MaaS y aigateway.modelsAsAService en el DataScienceCluster. Usar cuando el usuario pida habilitar o configurar MaaS.
---

# Configure MaaS

Ejecuta los pasos en orden desde la raíz del repo de este workshop (busca el directorio que contenga `manifests/maas/`; típico `~/opencode-maas-observability-workshop`). Verifica cada paso antes de seguir; si un paso falla, detente y reporta el error. Al final reporta el estado de todo en una tabla.

## 1. GatewayClass openshift-default

```sh
oc apply -f manifests/maas/gatewayclass.yaml
oc wait --for=condition=Accepted gatewayclass/openshift-default --timeout=2m
```

En este cluster `istiod-openshift-gateway` ya corre en `openshift-ingress` (RHOAI/llm-d), así que el controller ya está listo.

## 2. Instancia Kuadrant

```sh
oc create namespace kuadrant-system --dry-run=client -o yaml | oc apply -f -
oc apply -f manifests/maas/kuadrant.yaml
oc wait kuadrant/kuadrant -n kuadrant-system --for=condition=Ready --timeout=5m
```

Kuadrant (Connectivity Link) es la capa de políticas que MaaS usa (Authorino + Limitador). El Operator de Authorino ya viene pre-instalado globalmente: OLM lo reutiliza. Si OLM reporta `constraints not satisfiable`, desinstala la subscription pre-instalada de Authorino (`oc delete subscription authorino-operator -n openshift-operators`) y vuelve a esperar el Kuadrant. Si Kuadrant no queda `Ready` por "Gateway API provider not installed", reinicia el controller:

```sh
oc delete pod -n openshift-operators -l control-plane=controller-manager --field-selector=status.phase=Running
```

## 3. Postgres

```sh
oc apply -f manifests/maas/postgres.yaml
oc wait --for=condition=available deployment/maas-postgres -n redhat-ai-gateway-infra --timeout=300s
```

## 4. Gateway MaaS

```sh
bash manifests/maas/apply-gateway.sh
```

Debe imprimir `Gateway ready: https://maas.<cluster-domain>`. Verifica con `oc get gateway maas-default-gateway -n openshift-ingress` (`Programmed = True`).

## 5. Encender MaaS en el DataScienceCluster

```sh
oc patch dsc default-dsc --type merge -p '{"spec":{"components":{"aigateway":{"managementState":"Managed","modelsAsAService":{"managementState":"Managed"}}}}}'
```

Espera los pods `maas-api` y `maas-controller` en `Running` (namespace `redhat-ods-applications`, timeout 600s):

```sh
oc get pods -n redhat-ods-applications | grep -i maas
```

## Verificación final

- `oc get gatewayclass openshift-default` (`Accepted = True`)
- `oc get kuadrant kuadrant -n kuadrant-system` (`Ready`)
- `oc get pods -n redhat-ai-gateway-infra` (Postgres `Running`)
- `oc get gateway maas-default-gateway -n openshift-ingress` (`Programmed = True`)
- `oc get pods -n redhat-ods-applications | grep -i maas` (`maas-api`, `maas-controller` `Running`)
- `oc get dsc default-dsc` (`Ready`)

Nota: estos comandos tienen efecto real en el cluster. Muestra el plan antes de ejecutar cada paso.
