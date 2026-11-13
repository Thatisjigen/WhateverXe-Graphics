[ "${3:-/}" = / ] || exit 1
major=$(/usr/bin/sw_vers -productVersion)
if [ "${major%%.*}" = 26 ]; then
    feature=/Library/Preferences/FeatureFlags/Domain/CoreMedia.plist
    /bin/mkdir -p "${feature%/*}"
    if ! /usr/libexec/PlistBuddy -c 'Print :AllowOnePassMetalScaling' "$feature" >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c 'Add :AllowOnePassMetalScaling dict' "$feature"
    fi
    if /usr/libexec/PlistBuddy -c 'Print :AllowOnePassMetalScaling:Enabled' "$feature" >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c 'Set :AllowOnePassMetalScaling:Enabled false' "$feature"
    else
        /usr/libexec/PlistBuddy -c 'Add :AllowOnePassMetalScaling:Enabled bool false' "$feature"
    fi
fi

# The per-user Metal shader cache holds programs compiled for the graphics driver that was installed when they were
# built. After the drivers change they render corrupted on every display until they are rebuilt, so drop that cache for
# WindowServer and the console user; the package restarts the Mac and the cache rebuilds on the next boot. Only under
# the macOS Installer: the caches live outside the target volume, and a test run must not touch them.
clear_metal_cache() {
    [ -n "${INSTALLER_TEMP:-}" ] || return 0
    console=$(/usr/bin/stat -f '%Su' /dev/console 2>/dev/null)
    for user in _windowserver "$console"; do
        case "$user" in ''|root) continue ;; esac
        dir=$(/usr/bin/sudo -u "$user" /usr/bin/getconf DARWIN_USER_CACHE_DIR 2>/dev/null) || continue
        case "$dir" in */var/folders/*/C|*/var/folders/*/C/) ;; *) continue ;; esac
        for name in com.apple.metal com.apple.metalfe com.apple.gpuarchiver; do
            /usr/bin/find "$dir" -type d -name "$name" -prune -exec /bin/rm -rf {} + 2>/dev/null || :
        done
    done
}
clear_metal_cache
update_auxkc
