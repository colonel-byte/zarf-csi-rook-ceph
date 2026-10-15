#!/usr/bin/env bash
set -euo pipefail

# Find ceph-csi-drivers version from cluster/zarf.yaml
CSI_DRIVER_VER=$(yq '.components[].charts[] | select(.name == "ceph-csi-drivers") | .version' cluster/zarf.yaml)
echo "::debug::detected ceph-csi-drivers version: ${CSI_DRIVER_VER}"

# Map to ceph-csi-operator tag (e.g. v1.1.0). This assumes the ceph-csi-drivers chart
# version and the ceph-csi-operator git tag are kept in lockstep upstream.
OPERATOR_TAG="v${CSI_DRIVER_VER#v}"

# Fetch defaults.go from ceph-csi-operator repo
DEFAULTS_GO=$(curl -sSL --fail "https://raw.githubusercontent.com/ceph/ceph-csi-operator/${OPERATOR_TAG}/internal/controller/defaults.go")

parse_image() {
  local key="$1" image
  image=$(echo "$DEFAULTS_GO" | grep -E "\"${key}\":" | sed -E 's/.*"([^" ]+:[^" ]+)".*/\1/')
  if [[ $(echo "$image" | wc -l) -ne 1 || ! "$image" =~ ^[^[:space:]]+:[^[:space:]:]+$ ]]; then
    echo "error: could not parse a single '${key}' image from defaults.go (got: ${image})" >&2
    return 1
  fi
  echo "$image"
}

PROVISIONER=$(parse_image "provisioner")
ATTACHER=$(parse_image "attacher")
RESIZER=$(parse_image "resizer")
SNAPSHOTTER=$(parse_image "snapshotter")
REGISTRAR=$(parse_image "registrar")
PLUGIN=$(parse_image "plugin")
ADDONS=$(parse_image "addons")

echo "provisioner: $PROVISIONER"
echo "attacher: $ATTACHER"
echo "resizer: $RESIZER"
echo "snapshotter: $SNAPSHOTTER"
echo "registrar: $REGISTRAR"
echo "plugin: $PLUGIN"
echo "addons: $ADDONS"

# Extract tags
PROV_TAG="${PROVISIONER##*:}"
ATT_TAG="${ATTACHER##*:}"
RES_TAG="${RESIZER##*:}"
SNAP_TAG="${SNAPSHOTTER##*:}"
REG_TAG="${REGISTRAR##*:}"
PLUGIN_TAG="${PLUGIN##*:}"
ADDONS_TAG="${ADDONS##*:}"

# Update values/upstream-operator.yml and values/upstream-operator-seed.yml
for values_file in values/upstream-operator.yml values/upstream-operator-seed.yml; do
  yq -i "
    .csi.provisioner.tag = \"${PROV_TAG}\" |
    .csi.attacher.tag = \"${ATT_TAG}\" |
    .csi.resizer.tag = \"${RES_TAG}\" |
    .csi.snapshotter.tag = \"${SNAP_TAG}\" |
    .csi.registrar.tag = \"${REG_TAG}\" |
    .csi.cephcsi.tag = \"${PLUGIN_TAG}\" |
    .csi.csiAddons.tag = \"${ADDONS_TAG}\"
  " "$values_file"
done

echo "Successfully synchronized CSI driver tags to ceph-csi-operator ${OPERATOR_TAG}"
