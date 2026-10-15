# AGENTS.md

## Overview
This repository maintains the Zarf package definitions for deploying **Rook Ceph** (`csi-rook-ceph`) on Kubernetes. It packages the Rook operator, Ceph cluster definitions, Ceph CSI drivers (`ceph-csi-operator`), and creates the required storage classes and object bucket claims for air-gapped and connected environments.

## Repository Layout
- `zarf.yaml`: Main Zarf package configuration. Defines components (`operator-images`, `cluster-images`, `operator-seed-chart`, `cluster-seed-chart`, `operator-chart`, `cluster-chart`, `registry-bucket`).
- `operator/zarf.yaml`: Sub-package definition for the Rook Ceph operator chart (`oci://ghcr.io/rook/rook-ceph`).
- `cluster/zarf.yaml`: Sub-package definition for the Rook Ceph cluster chart (`oci://ghcr.io/rook/rook-ceph-cluster`) and the Ceph CSI drivers Helm chart (`ceph-csi-drivers`).
- `values/`: Helm values files layered during deployment:
  - `base-operator.yml`: Common operator settings (resources, node selector, tolerations, image pull secrets).
  - `base-cluster.yml`: Ceph cluster settings (mon/mgr/osd placement, encryption, storage pools, storage classes).
  - `base-csi-driver.yml`: Ceph CSI drivers configuration (`ceph-csi-operator-config`).
  - `upstream-operator.yml` / `upstream-operator-seed.yml`: Operator image overrides and explicit CSI driver sidecar images for connected and seed deployments.
  - `upstream-cluster.yml` / `upstream-cluster-seed.yml`: Ceph version and toolbox image overrides for connected and seed deployments.
- `.github/hack/`:
  - `sync-csi-images.sh`: Queries `ceph-csi-operator`'s upstream `defaults.go` for the exact CSI driver container image tags for the deployed `ceph-csi-drivers` version and syncs them into `values/upstream-operator*.yml`.
  - `zarf.sh`: Runs `sync-csi-images.sh`, then image discovery via `zarf dev find-images` across package components, and updates `zarf.yaml`. Aborts if the sync fails.
- `.github/renovate.json5`: Renovate Bot configuration managing dependencies, custom regex managers, and custom datasource for Ceph version matching upstream Rook charts.
- `.github/workflows/`: GitHub Actions for image cleanup, automated releases, and the Renovate workflow that automatically synchronizes Zarf images on PR updates.

## Key Architecture & Operating Guidelines
1. **Zarf Package Versioning:**
   - Package version in `zarf.yaml` follows `v<major>.<minor>.<patch>` (with the `v` prefix preserved).
   - Upstream Docker tags for `ghcr.io/rook/rook-ceph` carry no `v`, so the version line uses the
     dedicated `# renovate-version:` marker and a custom manager with an
     `autoReplaceStringTemplate` that re-adds the prefix on every bump. Do not switch it back to
     the shared `# renovate:` marker, which would strip the prefix.
2. **CSI Images in Air-Gapped Environments:**
   - Although Rook v1.21 charts leave CSI sidecar image values empty by default to use `ceph-csi-operator` built-ins, Zarf requires explicit image tags in `values/upstream-operator*.yml` so that all sidecar images are discovered, bundled, and rewritten to local/seed registries.
   - Use `./.github/hack/sync-csi-images.sh` to synchronize CSI sidecar image tags with `ceph-csi-operator`.
3. **Image Discovery & Verification:**
   - Discover images: `zarf dev find-images --flavor upstream --skip-cosign .`
   - Re-sync package images: `./.github/hack/zarf.sh`
   - Package creation test: `zarf package create --confirm --flavor upstream .`
