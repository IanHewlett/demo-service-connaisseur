#!/usr/bin/env just --justfile

@_default:
  just --list

get-vars instance:
  @vault kv get -format=json -namespace=admin secret/svc/env-values/{{instance}} | jq -r '.data.data."{{instance}}"' | yq -p json -o yaml > inputs.yaml

test-spec instance: (get-vars instance)
  inspec exec spec --tags=spec --input-file inputs.yaml
