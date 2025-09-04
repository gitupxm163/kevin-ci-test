# k8s load testing ci

kubernetes ci pipeline with load testing for take home assignment.

## what it does

on PR to main:
1. creates kind cluster (1 control + 2 workers)  
2. deploys nginx ingress
3. deploys 2 http-echo apps (foo, bar)
4. configures routing:
   - foo.localhost -> foo app
   - bar.localhost -> bar app  
5. runs health checks
6. load tests both endpoints
7. posts results as PR comment

## files

- `.github/workflows/ci.yml` - main ci config
- `kind-cluster-config.yaml` - cluster setup (multi node)
- `k8s/` - deployment configs for foo/bar apps + ingress 
- `scripts/` - bash scripts for deploy/test/health check

## local testing

run local test:
```bash
./test-local.sh
```

manual setup:
```bash
kind create cluster --config=kind-cluster-config.yaml --name=ci-test
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
./scripts/deploy-apps.sh
./scripts/verify-health.sh  
./scripts/load-test.sh
```

cleanup: `kind delete cluster --name=ci-test`

## development process

this took several iterations to get right:

1. **initial setup** - started with basic kind config and workflow
2. **local testing** - run `./test-local.sh` multiple times to debug issues:
   - port-forward connectivity issues (added sleep delays)
   - hey tool installation failures (switched to wget approach) and change -H to -host, it takes me a lot of time to find this issue, before this, it`s always response 404.

## debugging notes

common issues i encountered:
- **ingress not ready**: need to wait for controller pod before deploying apps
- **port-forward timing**: need sleep after backgrounding port-forward
- **hey installation**: some ci runners don't have hey pre-installed
- **context naming**: kind cluster context is `kind-<cluster-name>`

## tools used

- kind - lightweight k8s for ci
- nginx ingress - standard ingress controller  
- hashicorp/http-echo - simple echo server
- hey - http load testing
- github actions + gh cli

## time spent

about 4 hours total:
- design and local test 2.5
- scripts: 1h  
- docs: 0.5h

most time was spent on local testing and debugging ingress timing issues.