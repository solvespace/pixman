#!/bin/sh -eu

version=
prev=

cairo_dest=cairographics.org:/srv/cairo.freedesktop.org/www/releases
xorg_dest=xorg.freedesktop.org:/srv/xorg.freedesktop.org/archive/individual/lib

cairo_url=https://cairographics.org/releases
xorg_url=https://www.x.org/releases/individual/lib

tar_gz="pixman-$version.tar.gz"
tar_xz="pixman-$version.tar.xz"

sha512_tgz="$tar_gz.sha512"
pgp_sig="$sha512_tgz.asc"

announce="pixman-$version.eml"

meson dist -C build/ --formats xztar,gztar
cd build/meson-dist/
sha512sum "$tar_gz" >"$sha512_tgz"
gpg --armor --sign "$sha512_tgz"
scp "$tar_gz" "$sha512_tgz" "$pgp_sig" "$cairo_dest"
scp "$tar_gz" "$tar_xz" "$xorg_dest"
git tag -m "pixman $version release" "pixman-$version"
git push --follow-tags

cat >"$announce" <<EOF
To: cairo-announce@cairographics.org, xorg-announce@lists.freedesktop.org, pixman@lists.freedesktop.org
Subject: [ANNOUNCE] pixman release $version now available

A new pixman release $version is now available.

tar.gz:
	$cairo_url/$tar_gz
	$xorg_url/$tar_gz

tar.xz:
	$xorg_url/$tar_xz

Hashes:
	SHA256: $(sha256sum "$tar_gz")
	SHA256: $(sha256sum "$tar_xz")
	SHA512: $(sha512sum "$tar_gz")
	SHA512: $(sha512sum "$tar_xz")

PGP signature:
	$cairo_url/$pgp_sig

Git:
	https://gitlab.freedesktop.org/pixman/pixman.git
	tag: pixman-$version

Log:
$(git log --no-merges "pixman-$prev".."pixman-$version" | git shortlog | awk '{ printf "\t"; print ; }' | cut -b1-80)
EOF
