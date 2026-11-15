# Zarf Package, Rook-ceph

A `zarf.dev/v1beta1` package. Deploy-time configuration lives in [`values.yaml`](values.yaml);
override it with `--set-values` or `--values` on `zarf package deploy`.

## Components:
- `operator-images`
    - The images required for the rook-ceph operator, this includes the oci helm chart
- `cluster-images`
    - The images required for the rook-ceph cluster resources, this includes the oci helm chart
- **The following chart components includes my own configuration for ceph**
- `operator-chart`
    - The helm chart for deploying the rook-ceph operator, after the zarf registry is configured
- `cluster-chart`
    - The helm chart for deploying the rook-ceph cluster, after the zarf registry is configured
- `operator-seed-chart`
    - The helm chart for deploying  the rook-ceph operator, during the seeding phase of the zarf lifecycle
- `cluster-seed-chart`
    - The helm chart for deploying the rook-ceph cluster, during the seeding phase of the zarf lifecycle
