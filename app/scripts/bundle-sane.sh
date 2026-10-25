#!/usr/bin/env bash
# Copy scanimage, libsane with only the fujitsu backend, and their Homebrew
# dylibs into DEST, rewriting load paths so nothing points at /opt/homebrew.
#
# Usage: bundle-sane.sh DEST     (DEST becomes DEST/bin, DEST/lib, DEST/etc)
set -euo pipefail

dest="$1"
sane="$(brew --prefix sane-backends)"

rm -rf "$dest"
mkdir -p "$dest/bin" "$dest/lib/sane" "$dest/etc/sane.d"

cp "$sane/bin/scanimage" "$dest/bin/"
cp "$sane/lib/libsane.1.dylib" "$dest/lib/"
cp "$sane/lib/sane/libsane-fujitsu.1.so" "$dest/lib/sane/"
cp "$sane/etc/sane.d/fujitsu.conf" "$dest/etc/sane.d/"
echo fujitsu > "$dest/etc/sane.d/dll.conf"
chmod u+w "$dest"/bin/* "$dest"/lib/*.dylib "$dest"/lib/sane/*

# Copy every /opt/homebrew dylib a file links against (recursively) into lib/
# and point the reference at it relative to the file
fix() {
  local file="$1" rel="$2" dep name
  for dep in $(otool -L "$file" | tail -n +2 | awk '{print $1}' | grep -E '^/opt/homebrew|^/usr/local' || true); do
    name="$(basename "$dep")"
    # libsane's own versioned name points at the copy we already made
    [[ "$name" == libsane*.dylib ]] && name="libsane.1.dylib"
    if [[ ! -f "$dest/lib/$name" ]]; then
      cp "$(realpath "$dep")" "$dest/lib/$name"
      chmod u+w "$dest/lib/$name"
      install_name_tool -id "@loader_path/$name" "$dest/lib/$name" 2>/dev/null
      fix "$dest/lib/$name" "@loader_path"
    fi
    install_name_tool -change "$dep" "$rel/$name" "$file" 2>/dev/null
  done
}

install_name_tool -id "@loader_path/libsane.1.dylib" "$dest/lib/libsane.1.dylib" 2>/dev/null
fix "$dest/bin/scanimage" "@executable_path/../lib"
fix "$dest/lib/libsane.1.dylib" "@loader_path"
fix "$dest/lib/sane/libsane-fujitsu.1.so" "@loader_path/.."

# Modified binaries need a fresh signature on Apple silicon
find "$dest" -type f \( -perm -u+x -o -name '*.dylib' -o -name '*.so' \) -exec codesign --force --sign - {} \; 2>/dev/null

for f in "$dest"/bin/* "$dest"/lib/*.dylib "$dest"/lib/sane/*; do
  if otool -L "$f" | tail -n +2 | grep -q -E '/opt/homebrew|/usr/local'; then
    echo "Still links against Homebrew: $f" >&2
    exit 1
  fi
done
echo "SANE bundled into $dest"
