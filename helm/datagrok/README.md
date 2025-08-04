# Application chart

## Deploy

```sh
helm upgrade --install datagrok ./datagrok \
  --namespace datagrok-<STAGE>  \
  --values ./values-<STAGE>.yaml \
  --set ingress_subdomain="<STAGE>" \
  --set image.tag=<TAG> \
  --wait
```

## Releases

```sh
helm list -n <namespace> datagrok --all
```

```sh
helm history -n <namespace> datagrok
```

## Rollback deployment

```sh
helm -n <namespace> rollback datagrok <number_of_release>
```
