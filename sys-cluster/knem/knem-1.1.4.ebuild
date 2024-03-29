# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools
#inherit autotools linux-mod linux-info toolchain-funcs udev multilib

DESCRIPTION="High-Performance Intra-Node MPI Communication"
HOMEPAGE="http://runtime.bordeaux.inria.fr/knem/"
if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://gforge.inria.fr/git/knem/knem.git"
	inherit git-2
	KEYWORDS=""
else
	SRC_URI="http://gforge.inria.fr/frs/download.php/37186/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-2 LGPL-2"
SLOT="0"
IUSE="debug modules"

#DEPEND="
#		sys-apps/hwloc
#		modules? ( virtual/linux-sources )"
#RDEPEND="
#		sys-apps/hwloc
#		modules? ( virtual/modutils )"

KERNEL_DIR="${EPREFIX}/${KERNEL_DIR}"
MODULE_NAMES="knem(misc:${S}/driver/linux)"
BUILD_TARGETS="all"
BUILD_PARAMS="KDIR=${KERNEL_DIR}"

pkg_setup() {
	linux-info_pkg_setup
	#CONFIG_CHECK="DMA_ENGINE"
	#check_extra_config
	#linux-mod_pkg_setup
	ARCH="$(tc-arch-kernel)"
	ABI="${KERNEL_ABI}"
}

src_prepare() {
	sed 's:driver/linux::g' -i Makefile.am
	eautoreconf
	default
}

src_configure() {
	true
	#econf \
	#	--enable-hwloc \
	#	--with-linux="${KERNEL_DIR}" \
	#	--with-linux-release=${KV_FULL} \
	#		$(use_enable debug)
}

src_compile() {
	true
	#default
	if use modules; then
		cd "${S}/driver/linux"
		linux-mod_src_compile || die "failed to build driver"
	fi
}

src_install() {
	#default
	if use modules; then
		cd "${S}/driver/linux"
		linux-mod_src_install || die "failed to install driver"
	fi

	# Drop funny unneded stuff
	#rm "${ED}/usr/sbin/knem_local_install" || die
	#rmdir "${ED}/usr/sbin" || die
	# install udev rules
	#udev_dorules "${FILESDIR}/45-knem.rules"
	#rm "${ED}/etc/10-knem.rules" || die
	mkdir -p "${D}/${EPREFIX}/usr/include"
	install -m644 common/knem_io.h "${D}/${EPREFIX}/usr/include"
}
