# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

JAVA_PKG_OPT_USE=viewer
inherit cmake desktop java-pkg-opt-2 verify-sig

DESCRIPTION="A fast replacement for TigerVNC"
HOMEPAGE="https://www.turbovnc.org/"
SRC_URI="
	https://sourceforge.net/projects/turbovnc/files/${PV}/${P}.tar.gz/download -> ${P}.tar.gz
	verify-sig? ( https://sourceforge.net/projects/turbovnc/files/${PV}/${P}.tar.gz.sig/download -> ${P}.tar.gz.sig )
"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+server +ssl +viewer"
REQUIRED_USE="|| ( server viewer )"

COMMON_DEPEND="
	x11-apps/xauth
	x11-libs/libX11
	x11-libs/libXext
	x11-misc/xkeyboard-config
	server? (
		media-libs/libjpeg-turbo:=
		sys-libs/pam
		sys-libs/zlib
		virtual/opengl
		x11-libs/libXau
		x11-libs/libXdmcp
		x11-libs/libXfont2
		x11-libs/pixman
		ssl? ( dev-libs/openssl:= )
		!net-misc/tigervnc[server]
	)
	viewer? (
		media-libs/libjpeg-turbo:=[java]
		x11-libs/libXi
		!net-misc/tigervnc[viewer(+)]
	)
"

RDEPEND="
	${COMMON_DEPEND}
	x11-apps/xkbcomp
	viewer? ( >=virtual/jre-1.8:* )
"

# libbz2.so.1, libfontenc.so.1 and libfreetype.so.6 are used by libXfont2.so.2
# but cmake will look for them, so add them here
DEPEND="
	${COMMON_DEPEND}
	x11-libs/xtrans
	viewer? ( >=virtual/jdk-1.8:* )
	server? (
		app-arch/bzip2
		media-libs/freetype
		x11-libs/libfontenc
	)
"

BDEPEND="
	verify-sig? ( sec-keys/openpgp-keys-vgl-turbovnc )
"

VERIFY_SIG_OPENPGP_KEY_PATH="${BROOT}"/usr/share/openpgp-keys/vgl-turbovnc.asc

#879797 - BSD functions
QA_CONFIG_IMPL_DECL_SKIP=( strlcat strlcpy )

pkg_pretend() {
	if use ssl && ! use server; then
		einfo "USE=\"ssl\" selected but USE=\"server\" is not.  The SSL support is unused"
	fi
}

src_prepare() {
	use viewer && java-pkg-opt-2_src_prepare
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DTVNC_BUILDVIEWER=$(usex viewer)
		-DTVNC_BUILDHELPER=$(usex viewer)
		-DTVNC_BUILDSERVER=$(usex server)
		-DTVNC_BUILDWEBSERVER=$(usex server)
	)

	if use server ; then
		mycmakeargs+=(
			-DTVNC_SYSTEMLIBS=ON
			-DTVNC_SYSTEMX11=ON
			-DXKB_BIN_DIRECTORY=${EPREFIX}/usr/bin
			-DXKB_DFLT_RULES=base
			-DCMAKE_INSTALL_SYSCONFDIR=${EPREFIX}/etc
			-DXORG_DRI_DRIVER_PATH=${EPREFIX}/usr/lib64/dri
			-DXKB_BASE_DIRECTORY=${EPREFIX}/usr/share/X11/xkb
			-DXORG_FONT_PATH=${EPREFIX}/usr/share/fonts/misc/,${EPREFIX}/usr/share/fonts/Type1/,${EPREFIX}/usr/share/fonts/75dpi/,${EPREFIX}/usr/share/fonts/100dpi/
			-DXORG_REGISTRY_PATH=${EPREFIX}/usr/lib64/xorg
		)
		if use ssl ; then
			# Link properly against OpenSSL to ensure
			# we catch e.g. ABI change
			# (i.e. don't dlopen it)
			mycmakeargs+=(
				-DTVNC_USETLS=OpenSSL
				-DTVNC_DLOPENSSL=OFF
			)
		else
			mycmakeargs+=( -DTVNC_USETLS=OFF )
		fi
	fi

	if use viewer ; then
		export JAVACFLAGS="$(java-pkg_javac-args)"
		export JNI_CFLAGS="$(java-pkg_get-jni-cflags)"
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	if use viewer ; then
		java-pkg_dojar "${BUILD_DIR}"/java/VncViewer.jar
		make_desktop_entry vncviewer "TurboVNC Viewer" /usr/share/icons/hicolor/48x48/apps/${PN}.png
	fi

	# Don't install incompatible init script
	rm -rf "${ED}"/etc/init.d/ || die
	rm -rf "${ED}"/etc/sysconfig/ || die

	# Conflicts with x11-base/xorg-server
	find "${ED}"/usr/share/man/man1/ -name Xserver.1\* -delete || die

	# don't need this in our setup
	rm "${ED}"/etc/turbovncserver-security.conf || die

	sed -i "s!/etc/X11/xinit!${EPREFIX}/etc/X11/xinit!" "${ED}"/usr/bin/xstartup.turbovnc || die
	sed -i "s!/usr/share/xsessions!${EPREFIX}/usr/share/xsessions!" "${ED}"/usr/bin/xstartup.turbovnc || die
	sed -i "s!/usr/bin/env!${EPREFIX}/usr/bin/env!" "${ED}"/usr/bin/vncserver || die
	sed -i 's!"gnome"!"mate"!' "${ED}"/usr/bin/xstartup.turbovnc || die

	einstalldocs
}
