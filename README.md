# KijaniKiosk Capstone: staged releases for kk-payments (Track A)

## 1. What is this?

kk-payments is the KijaniKiosk payments API. Before this project, a new version went straight to the only environment customers use. This repository adds a staging environment, a Jenkins pipeline with an approval step before production, automatic rollback in staging, and a simple error-rate check.

## 2. Architecture

![Architecture](docs/architecture.png)

| Folder | What it does |
| --- | --- |
| `app/` | The payments API, its tests and its Dockerfile |
| `terraform/` | Creates the `kijani-staging` namespace |
| `ansible/` | Creates the `kk-payments-config` ConfigMap in staging and production |
| `k8s/` | One Deployment and one Service, used for both environments |
| `Jenkinsfile` | Test, build and push, deploy staging, smoke test, approval, deploy production |
| `monitoring/` | `error-rate.sh` alerts when more than 5% of requests fail in 2 minutes |
| `docs/` | Scope, AI governance log, test plan, peer feedback, reflection |

## 3. Prerequisites

- Ubuntu with Docker, minikube, kubectl, Terraform and Ansible installed
- Jenkins with the Docker Pipeline plugin, running on the same machine
- A private Docker Hub repository `kk-payments` and an access token with Read and Write

## 4. Setup

```bash
# Step 1. Start the cluster and create the namespace and ConfigMaps.
minikube start --driver=docker
./scripts/setup.sh

# Step 2. Let staging pull the private image (production already has this secret from Week 8).
kubectl create secret docker-registry kijani-registry-credentials -n kijani-staging \
  --docker-server=https://index.docker.io/v1/ --docker-username=lenceneema --docker-password=<token>

# Step 3. Save the kubeconfig file that Jenkins will use.
kubectl config view --flatten --minify > ~/minikube-kubeconfig
```

In Jenkins, add two credentials: `dockerhub-credentials` (username and token) and `minikube-kubeconfig` (secret file, the file from Step 3). Then create a Pipeline job that reads the `Jenkinsfile` from this repository.

## 5. How to run the pipeline

- Push to `main` or click **Build with Parameters**. Leave `BAD_TAG` empty.
- When the pipeline reaches **Approval**, click Approve and write a reason.
- To test the rollback, run it with `BAD_TAG` set to `does-not-exist`. Staging rolls back and the pipeline stops before Approval.

## 6. How to verify

```bash
kubectl get pods -n kijani-staging
kubectl get pods -n default
kubectl exec -n kijani-staging deploy/kk-payments -- wget -qO- http://127.0.0.1:3001/health
kubectl rollout history deployment/kk-payments -n kijani-staging
./monitoring/error-rate.sh kijani-staging
```

`/health` should show the new version and `"environment":"staging"`.

## 7. Known limitations

- Staging and production are two namespaces on one minikube cluster, not two separate clusters.
- The registry secret for staging is created by hand, not by Ansible.
- Monitoring is a script you run, not a dashboard or a paging alert.
- There is no real database. `DB_HOST` is only a setting in the ConfigMap.
- The serverless receipt chain (Track B) is out of scope. See `docs/scope.md`.
