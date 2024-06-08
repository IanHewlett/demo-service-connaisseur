# MAINTAINERS

## Developing

### Configmap for Helm Values
https://github.com/fluxcd/flux2/issues/2330

### External Secrets


## Command Examples

### To get transit key with vault cli:
```bash
vault read -namespace=admin transit/keys/image_signing_key
````

### To verify an image signature:
```bash
cosign verify -key cosign.pub ghcr.io/ianhewlett/connaisseur:0.0.1
````

### To get image-pull-secret value:
```bash
kubectl get secrets -n connaisseur registry-credential --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode | jq -r '.auths."ghcr.io/ianhewlett".auth' | base64 --decode
````
