#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# We do not need anything here at all
rm -rf /usr/src
rm -rf /usr/share/doc
# Remove kernel-devel from rpmdb because all package files are removed from /usr/src
rpm --erase --nodeps kernel-devel

mkdir -p /usr/share/doc/bluefin
# Offline Bluefin documentation
ghcurl "https://github.com/ublue-os/bluefin-docs/releases/download/0.1/bluefin.pdf" --retry 3 -o /tmp/bluefin.pdf
install -Dm0644 -t /usr/share/doc/bluefin/ /tmp/bluefin.pdf

# Starship Shell Prompt
ghcurl "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" --retry 3 -o /tmp/starship.tar.gz
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin
# shellcheck disable=SC2016
echo 'eval "$(starship init bash)"' >>/etc/bashrc

# Automatic wallpaper changing by month
HARDCODED_RPM_MONTH="12"
sed -i "/picture-uri/ s/${HARDCODED_RPM_MONTH}/$(date +%m)/" "/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"
rm /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas

# Required for bluefin faces to work without conflicting with a ton of packages
rm -f /usr/share/pixmaps/faces/* || echo "Expected directory deletion to fail"
mv /usr/share/pixmaps/faces/bluefin/* /usr/share/pixmaps/faces
rm -rf /usr/share/pixmaps/faces/bluefin


# Remove desktop entries
if [[ -f /usr/share/applications/gnome-system-monitor.desktop ]]; then
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/gnome-system-monitor.desktop
fi
if [[ -f /usr/share/applications/org.gnome.SystemMonitor.desktop ]]; then
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/org.gnome.SystemMonitor.desktop
fi

# Add Mutter experimental-features
MUTTER_EXP_FEATS="'scale-monitor-framebuffer', 'xwayland-native-scaling'"
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
    MUTTER_EXP_FEATS="'kms-modifiers', ${MUTTER_EXP_FEATS}"
fi
tee /usr/share/glib-2.0/schemas/zz1-bluefin-modifications-mutter-exp-feats.gschema.override << EOF
[org.gnome.mutter]
experimental-features=[${MUTTER_EXP_FEATS}]
EOF

# Test bluefin gschema override for errors. If there are no errors, proceed with compiling bluefin gschema, which includes setting overrides.
mkdir -p /tmp/bluefin-schema-test
find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/bluefin-schema-test/ \;
cp /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override /tmp/bluefin-schema-test/
cp /usr/share/glib-2.0/schemas/zz1-bluefin-modifications-mutter-exp-feats.gschema.override /tmp/bluefin-schema-test/
echo "Running error test for bluefin gschema override. Aborting if failed."
# We should ideally refactor this to handle multiple GNOME version schemas better
glib-compile-schemas --strict /tmp/bluefin-schema-test
echo "Compiling gschema to include bluefin setting overrides"
glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null

# Hack nerd-font
curl -s -o /tmp/hack-nf-latest.zip -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
unzip -qo /tmp/hack-nf-latest.zip -d /tmp/hack-nf-fonts
mkdir -p /usr/share/fonts/hack-nf-fonts
mv /tmp/hack-nf-fonts/* /usr/share/fonts/hack-nf-fonts/
rm -rf /tmp/hack-nf*
fc-cache -f /usr/share/fonts/hack-nf-fonts
fc-cache --system-only --really-force --verbose

# globalproect-openconnect
curl -s -o /tmp/globalprotect-openconnect-latest.x86_64.rpm -L $(curl -s https://api.github.com/repos/yuezk/GlobalProtect-openconnect/releases/latest | jq -r '.assets[] | select(.name | contains ("x86_64.rpm")) | .browser_download_url' | head -n 1)
rpm-ostree install /tmp/globalprotect-openconnect-latest.x86_64.rpm
rm -r -f /tmp/globalprotect-openconnect-latest.x86_64.rpm

echo "::endgroup::"
