#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

curl --retry 3 -Lo /tmp/kind "https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-$(uname)-amd64"
chmod +x /tmp/kind
mv /tmp/kind /usr/bin/kind

# GitHub Monaspace Font
DOWNLOAD_URL=$(curl --retry 3 https://api.github.com/repos/githubnext/monaspace/releases/latest | jq -r '.assets[] | select(.name| test(".*.zip$")).browser_download_url')
curl --retry 3 -Lo /tmp/monaspace-font.zip "$DOWNLOAD_URL"

unzip -qo /tmp/monaspace-font.zip -d /tmp/monaspace-font
mkdir -p /usr/share/fonts/monaspace
mv /tmp/monaspace-font/monaspace-v*/fonts/variable/* /usr/share/fonts/monaspace/
rm -rf /tmp/monaspace-font*
fc-cache -f /usr/share/fonts/monaspace

# Hack nerd-font
curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r '.assets[] | select(.name | contains ("Hack.zip")) | .browser_download_url' | head -n 1 | xargs -I {} wget -O /tmp/hack-nf-latest.zip {}
unzip -qo /tmp/hack-nf-latest.zip -d /tmp/hack-nf-fonts
mkdir -p /usr/share/fonts/hack-nf-fonts
mv /tmp/hack-nf-fonts/* /usr/share/fonts/hack-nf-fonts/
rm -rf /tmp/hack-nf*
fc-cache -f /usr/share/fonts/hack-nf-fonts

fc-cache --system-only --really-force --verbose

# globalproect-openconnect
curl -s https://api.github.com/repos/yuezk/GlobalProtect-openconnect/releases/latest | jq -r '.assets[] | select(.name | contains ("x86_64.rpm")) | .browser_download_url' | head -n 1 | xargs -I {} wget -O /tmp/globalprotect-openconnect-latest.x86_64.rpm {}
rpm-ostree install /tmp/globalprotect-openconnect-latest.x86_64.rpm
rm -r -f /tmp/globalprotect-openconnect-latest.x86_64.rpm

echo "::endgroup::"
