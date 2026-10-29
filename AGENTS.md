# AGENTS.md

## Multica

- **Agente**: Agents MaaS Observability Expert (`f1381fd9-8115-4685-91ad-d7084ec28875`)
- **Proyecto**: Agents MaaS Observability (`6bfd22ab-f148-4beb-a89d-0da46fdc2524`) — recurso `local_directory` con `--execution-mode worktree`

## Workflow

- Al terminar cambios en la guía de este repo (el usuario la llama "showroom"), hacer siempre commit y `git push` a `origin/main`, sin preguntar.
- Commit messages en español, concisos, al estilo del historial (p. ej. "Modulo 7: ...").
- Antes de commitear: `git status`, `git diff` y `git log --oneline -5`; stage solo los archivos del cambio.

## App demo API Key (cluster Summit Connect)

- **Proyecto OpenShift**: `apikey-demo`
- **App**: deployment `apikey-demo` — página web que muestra el valor de la API key. Manifiesto en `manifests/apikey-demo/apikey-demo.yaml`.
- **URL**: https://apikey-demo-apikey-demo.apps.ocp.nzbcx.sandbox80.opentlc.com
- **Secret**: `apikey-secret` (namespace `apikey-demo`), clave `API_KEY`. Valor inicial `XXXXX`; el usuario lo actualiza manualmente.
- **Actualizar la API key** (no re-aplicar el manifiesto, machacaría el valor manual del secret):

  ```bash
  oc -n apikey-demo create secret generic apikey-secret \
    --from-literal=API_KEY=<nuevo-valor> --dry-run=client -o yaml | oc apply -f -
  oc -n apikey-demo rollout restart deployment/apikey-demo
  ```

- **Nota**: la ruta usa terminación `edge` (obligatorio en este cluster; una ruta HTTP plano solo responde por puerto 80).
