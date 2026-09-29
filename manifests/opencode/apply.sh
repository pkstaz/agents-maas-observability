#!/usr/bin/env bash
# Build the OpenCode image and deploy the pod (opencode serve + oc).
#
# Default: OpenShift internal registry, namespace `opencode`.
#   NS=<namespace> bash manifests/opencode/apply.sh
# Optional pre-pushed image:
#   OPENCODE_IMAGE=quay.io/<user>/opencode-agent:latest bash manifests/opencode/apply.sh
#
# Discovers the Qwen L4 route (module 3) and injects it into opencode.jsonc.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NS="${NS:-opencode}"
APP=opencode-agent
CTX="manifests/opencode"
OPENCODE_IMAGE="${OPENCODE_IMAGE:-}"

echo "=== Namespace ${NS} ==="
oc get ns "$NS" >/dev/null 2>&1 || oc new-project "$NS" >/dev/null
oc label ns "$NS" opendatahub.io/dashboard=true --overwrite >/dev/null 2>&1 || true

if [[ -n "$OPENCODE_IMAGE" ]]; then
  IMAGE="$OPENCODE_IMAGE"
  echo "Using pre-pushed image $IMAGE"
else
  echo "=== BuildConfig in cluster registry ==="
  oc -n "$NS" new-build --binary --name="$APP" --strategy=docker \
    --to="${APP}:latest" 2>/dev/null || true
  oc -n "$NS" start-build "$APP" --from-dir="${ROOT}/${CTX}" --follow --wait
  IMAGE="image-registry.openshift-image-registry.svc:5000/${NS}/${APP}:latest"
fi

echo "=== Config opencode.jsonc (Qwen L4) ==="
MODEL_ROUTE=$(oc get routes -n llm -o jsonpath='{range .items[*]}{.spec.host}{"\n"}{end}' 2>/dev/null | grep qwen25 | head -1 || true)
if [[ -z "$MODEL_ROUTE" ]]; then
  echo "WARNING: no encontre la ruta del modelo qwen25 en namespace llm (module 3). Config con baseURL placeholder." >&2
  MODEL_ROUTE="<MODEL_ROUTE>"
fi
cat > /tmp/opencode.jsonc <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "qwen-l4": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Qwen2.5-Coder-7B-AWQ (L4)",
      "options": {
        "baseURL": "https://${MODEL_ROUTE}/v1",
        "apiKey": "none"
      },
      "models": {
        "qwen25-coder-7b-awq": {}
      }
    }
  },
  "model": "qwen-l4/qwen25-coder-7b-awq"
}
EOF
oc -n "$NS" create configmap opencode-config \
  --from-file=opencode.jsonc=/tmp/opencode.jsonc \
  --dry-run=client -o yaml | oc apply -f -

echo "=== Deploy ==="
tmp=$(mktemp)
sed -e "s|namespace: opencode|namespace: ${NS}|g" \
    -e "s|image: image-registry.openshift-image-registry.svc:5000/opencode/opencode-agent:latest|image: ${IMAGE}|" \
    "${ROOT}/manifests/opencode/deploy.yaml" > "$tmp"
oc apply -n "$NS" -f "$tmp"
rm -f "$tmp"

oc rollout status deploy/"$APP" -n "$NS" --timeout=300s || true
oc get deploy,svc,route -n "$NS" "$APP"
echo
echo "Endpoint: https://$(oc -n "$NS" get route "$APP" -o jsonpath='{.spec.host}')"
