# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit cmake-multilib flag-o-matic multilib systemd

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/VirtualGL/${PN}.git"
	inherit git-r3
else
	MY_PN="VirtualGL"
	MY_P="${MY_PN}-${PV}"
	S="${WORKDIR}/${MY_P}"
	SRC_URI="mirror://sourceforge/project/${PN}/${PV}/${MY_P}.tar.gz"
	KEYWORDS="amd64 ~arm64 x86"
fi

DESCRIPTION="Run OpenGL applications remotely with full 3D hardware acceleration"
HOMEPAGE="https://www.virtualgl.org/"

SLOT="0"
LICENSE="LGPL-2.1 wxWinLL-3.1 FLTK"
IUSE="libressl ssl"

RDEPEND="
	ssl? (
		!libressl? ( dev-libs/openssl:0=[${MULTILIB_USEDEP}] )
		libressl? ( dev-libs/libressl:0=[${MULTILIB_USEDEP}] )
	)
	media-libs/libjpeg-turbo[${MULTILIB_USEDEP}]
	x11-libs/libX11[${MULTILIB_USEDEP}]
	x11-libs/libXext[${MULTILIB_USEDEP}]
	x11-libs/libXtst[${MULTILIB_USEDEP}]
	x11-libs/libXv[${MULTILIB_USEDEP}]
	virtual/glu[${MULTILIB_USEDEP}]
	virtual/opengl[${MULTILIB_USEDEP}]
	amd64? ( abi_x86_32? (
		>=media-libs/libjpeg-turbo-1.3.0-r3[abi_x86_32]
		>=x11-libs/libX11-1.6.2[abi_x86_32]
		>=x11-libs/libXext-1.3.2[abi_x86_32]
		>=x11-libs/libXtst-1.2.3[abi_x86_32]
		>=x11-libs/libXv-1.0.10[abi_x86_32]
		>=virtual/glu-9.0-r1[abi_x86_32]
		>=virtual/opengl-7.0-r1[abi_x86_32]
	) )
"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}"/find-host-vgl-libraries.patch
)

src_prepare() {
	# Use /var/lib, bug #428122
	sed -e "s#/etc/opt#/var/lib#g" -i doc/unixconfig.txt doc/index.html doc/advancedopengl.txt \
		server/vglrun.in server/vglgenkey server/vglserver_config || die

	cmake-utils_src_prepare
}

src_configure() {
	# Completely breaks steam/wine for discrete graphics otherwise
	# see https://github.com/VirtualGL/virtualgl/issues/16
	append-ldflags "-Wl,--no-as-needed"

	abi_configure() {
		local mycmakeargs=(
			-DVGL_USESSL="$(usex ssl)"
			-DVGL_FAKEOPENCL=OFF
			-DCMAKE_INSTALL_DOCDIR="${EPREFIX}/usr/share/doc/${PF}"
			-DTJPEG_INCLUDE_DIR="${EPREFIX}/usr/include"
			-DCMAKE_INSTALL_LIBDIR="${EPREFIX}/usr/$(get_libdir)/VirtualGL"
			-DTJPEG_LIBRARY="${EPREFIX}/usr/$(get_libdir)/libturbojpeg.so"
			-DCMAKE_LIBRARY_PATH="${EPREFIX}/usr/$(get_libdir)"
		)
		cmake-utils_src_configure
	}
	multilib_parallel_foreach_abi abi_configure
}

src_install() {
	cmake-multilib_src_install

	# Make config dir
	#dodir /var/lib/VirtualGL
	#fowners root:video /var/lib/VirtualGL
	#fperms 0750 /var/lib/VirtualGL
	newinitd "${FILESDIR}/vgl.initd-r3" vgl
	newconfd "${FILESDIR}/vgl.confd-r2" vgl

	exeinto /usr/libexec
	doexe "${FILESDIR}/vgl-helper.sh"
	systemd_dounit "${FILESDIR}/vgl.service"

	# Rename glxinfo to vglxinfo to avoid conflict with x11-apps/mesa-progs
	mv "${ED}"/usr/bin/{,v}glxinfo || die
	# Rename elxinfo to veglinfo to avoid conflict with x11-apps/mesa-progs
	mv "${ED}"/usr/bin/{,v}eglinfo || die
	# Remove license files, bug 536284
	rm "${ED}"/usr/share/doc/${PF}/{LGPL.txt*,LICENSE*} || die

	# don't use LD_LIBRARY_PATH for faker libs
	rm "${ED}"/usr/bin/.vglrun.vars64 || die
	echo "LDPATH=${EPREFIX}/usr/$(get_libdir)/VirtualGL" > 99virtualgl || die
	doenvd 99virtualgl
}
