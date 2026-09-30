---
name: configure-maas
description: Configura Models as a Service (MaaS) en este cluster OpenShift AI — GatewayClass openshift-default, Istio, instancia Kuadrant (Connectivity Link), postgres, gateway MaaS y aigateway.modelsAsAService en el DataScienceCluster. Usar cuando el usuario pida habilitar o configurar MaaS.
---

# Configure MaaS

Ejecuta los pasos en orden contra el cluster donde ya hay `oc login`. Los manifiestos vienen del repo `rhoai-showroom`: clonalo si no existe, entra al directorio y ejecuta cada tarea desde ahí. Verifica cada paso antes de seguir; si un paso falla, detente y reporta el error. Al final reporta el estado de todo en una tabla y sale del repo con `cd ..`.

## 0. Clonar el repo

```sh
[ -d rhoai-showroom ] || git clone https://github.com/pkstaz/rhoai-showroom.git
cd rhoai-showroom
```

## 1. GatewayClass openshift-default

```sh
oc apply -f manifests/maas/gatewayclass.yaml
oc wait --for=condition=Accepted gatewayclass/openshift-default --timeout=2m
```

## 2. Esperar Istio (antes de Kuadrant)

No crees la instancia Kuadrant hasta que Istio esté listo; si Kuadrant arranca antes, el Operator no detecta el provider:

```sh
oc rollout status -n openshift-ingress deploy/istiod-openshift-gateway --timeout=5m
```

## 3. Instancia Kuadrant

```sh
oc create namespace kuadrant-system --dry-run=client -o yaml | oc apply -f -
oc apply -f manifests/maas/kuadrant.yaml
oc wait kuadrant/kuadrant -n kuadrant-system --for=condition=Ready --timeout=5m
```

Si Kuadrant no queda `Ready` con `Gateway API provider (istio / envoy gateway) is not installed`, reinicia el controller de Kuadrant y vuelve a chequear:

```sh
oc delete pod -n openshift-operators -l control-plane=controller-manager --field-selector=status.phase=Running
oc rollout status -n openshift-operators deploy/kuadrant-operator-controller-manager --timeout=3m
oc get kuadrant -n kuadrant-system
```

## 4. Postgres

```sh
oc apply -f manifests/maas/maas-postgres.yaml
oc wait --for=condition=available deployment/maas-postgres -n redhat-ai-gateway-infra --timeout=300s
```

El YAML crea el Secret `maas-db-config`.

## 5. Gateway MaaS

```sh
bash manifests/apply-maas-gateway.sh
oc get gateway maas-default-gateway -n openshift-ingress
```

Debe imprimir la URL del gateway y quedar `Programmed = True`.

## 6. Encender MaaS en el DataScienceCluster

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
- `oc get aitenant -A` y `oc get maastenantconfig -A`

Al terminar, `cd ..` para salir del repo.

Nota: estos comandos tienen efecto real en el cluster. Muestra el plan antes de ejecutar cada paso.
