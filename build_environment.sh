#!/usr/bin/env bash

set -e

MANIFEST_URL="https://www.tool.sony.biz/tv-gerrit/mtk/dtv/mediatek/manifest"
DOCKER_IMAGE="43.74.11.8:5005/ubuntu-18-jenkins-cloud-env:v0.2"

read -p "Enter new workspace name [Chutoro]: " NEW_WORKSPACE_INPUT
read -p "Enter old workspace name to delete (leave empty to skip delete) [Chutoro_main_branch]: " OLD_WORKSPACE_INPUT
read -p "Enter environment tag [default]: " MANIFEST_INPUT

WORKSPACE_NAME="${NEW_WORKSPACE_INPUT:-Chutoro}"
MANIFEST_REF="${MANIFEST_INPUT:-refs/builds/t-sony-apollo-mp-2103-refu-fy25-1105-001-468-001-177}"

echo "==> Workspace Directory: ${WORKSPACE_NAME}"
echo "==> Manifest Reference:  ${MANIFEST_REF}"

read -p "Continue? This may delete the old workspace. [Y/n]: " CONFIRM

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "Build cancelled."
    exit 0
fi

if [[ -n "$OLD_WORKSPACE_INPUT" ]]; then
    echo "==> Step 1: Deleting old workspace: ${OLD_WORKSPACE_INPUT}"

    if [[ "$OLD_WORKSPACE_INPUT" == "/" || "$OLD_WORKSPACE_INPUT" == "." || "$OLD_WORKSPACE_INPUT" == ".." ]]; then
        echo "ERROR: Invalid workspace path."
        exit 1
    fi

    rm -rf "${OLD_WORKSPACE_INPUT}"
else
    echo "==> Step 1: Skipping old workspace deletion."
fi

echo "==> Step 2: Creating new workspace..."
mkdir "${WORKSPACE_NAME}"

echo "==> Step 3: Entering workspace..."
cd "${WORKSPACE_NAME}"

echo "==> Step 4: Initializing repository..."
repo init --depth=1 -u "${MANIFEST_URL}" -b "${MANIFEST_REF}"

echo "==> Step 5: Syncing repository..."
repo sync --force-sync -j8

echo "==> Step 6-10: Executing build inside Docker container..."
docker run -it \
  -v /etc/group:/etc/group:ro \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/shadow:/etc/shadow:ro \
  -u "$(id -u "${USER}")" \
  -e "USER=${USER}" \
  -e "HOME=${HOME}" \
  -w "$(pwd)" \
  -v "/home/${USER}:/home/${USER}" \
  "${DOCKER_IMAGE}" \
  /bin/bash -c "
    set -e
    bash vendor/mediatek/tv/build/android/android_u_base_build_aow.sh
    source build/envsetup.sh
    lunch BRAVIA_CT1-userdebug
    m custom_images droid 2>&1 | tee t7x_full_build.log
    echo '==> Build finished! Leaving container open...'
    exec bash --rcfile <(echo 'source build/envsetup.sh; lunch BRAVIA_CT1-userdebug')
  "

echo "==> Build script completed successfully!"
