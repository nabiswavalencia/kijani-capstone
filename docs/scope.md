# Capstone Scope Document

**Track:** A (Infrastructure-first) · **Author:** Valencia Neema · **Date:** 11 November 2026

## Problem Statement

kk-payments deploys to a single environment (the `default` namespace on a minikube cluster). There is
no staging environment, so a new version is first tried by customers. Releases are manual
`kubectl apply` commands with no automated health validation, no human approval step and no
automatic rollback, and there is no signal that tells the team when payments start failing.

## Track

Track A: Infrastructure-first.

## What I Will Build

- A `kijani-staging` namespace created by Terraform and configured by Ansible (one ConfigMap per environment).
- One Deployment manifest used for both environments, with readiness and liveness probes, resource limits and an environment-specific ConfigMap (different `DB_HOST`).
- A Jenkins pipeline: lint and test, build and push a `<version>-<sha>` image, deploy to staging, smoke test, approval gate with a recorded reason, deploy to production.
- Automatic rollback in staging when a rollout or smoke test fails.
- A log-based monitoring signal: alert when the 5xx rate exceeds 5% over 2 minutes.

## What Is Out of Scope

- **Week 10 serverless receipt chain**: adding it would leave no time to test the pipeline end to end.
- **Prometheus and Alertmanager**: the laptop is close to its disk limit; Option B gives the same signal from existing logs.
- **A real database**: `DB_HOST` proves configuration separation; storing payments is a separate project.

## Success Criteria

1. A push to `main` deploys the new version to `kijani-staging` with no manual step, and `kubectl rollout status` returns success.
2. Production changes only after a person approves in Jenkins; the build log shows the approver and the reason.
3. A release with a bad image tag is rolled back in staging and the pipeline stops before the approval gate; production keeps serving the previous version.

## Architecture Diagram

![Architecture](architecture.png)
