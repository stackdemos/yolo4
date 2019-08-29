#!/bin/bash -e
# shellcheck disable=SC2155

export MC_HOME="$(pwd)/.mc"

NAMESPACE="${NAMESPACE:-minio}"
DOMAIN_NAME="${DOMAIN_NAME:-localhost}"
BUCKET="${BUCKET:-default}"
SECRET_NAME="${SECRET_NAME:-minio}"
ACCESS_KEY_REF="${ACCESS_KEY_REF:=accesskey}"
SECRET_KEY_REF="${SECRET_KEY_REF:-secretkey}"
ARCH="$(uname -s | tr '[:upper:]' '[:lower:]')"

kubectl="kubectl --context=$DOMAIN_NAME --namespace=$NAMESPACE"
base64_decode='base64 -d'
mc='mc --no-color --insecure'

if test "$ARCH" == "darwin"; then
    base64_decode='base64 --decode'
fi

if test "$INGRESS_PROTOCOL" == "https"; then
    mc='mc --no-color'
fi

ALIAS="superhub"
ACCESS_KEY=$($kubectl get secret "$SECRET_NAME" -o "json" | jq -r ".data?.$ACCESS_KEY_REF" | $base64_decode)
SECRET_KEY=$($kubectl get secret "$SECRET_NAME" -o "json" | jq -r ".data?.$SECRET_KEY_REF" | $base64_decode)

# shellcheck disable=SC2046
export MC_HOSTS_${ALIAS}="$INGRESS_PORTOCOL://$ACCESS_KEY:$SECRET_KEY@$ENDPOINT"

$mc rm -r --force "$ALIAS/$BUCKET" || true
$mc ls "$ALIAS" || true
