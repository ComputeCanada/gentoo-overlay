# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit udev

DESCRIPTION="OpenIB userspace driver for the PathScale InfiniBand HCAs"
SRC_URI="https://www.openfabrics.org/downloads/${PN}-psm/${P}-19_g67c0807_open.tar.gz"

SLOT="0"
KEYWORDS="amd64 ~x86 ~amd64-linux"
IUSE=""

RDEPEND="sys-fabric/rdma-core:${SLOT}"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S="${WORKDIR}/${P}-19_g67c0807_open"

PATCHES=(
	"${FILESDIR}/${P}-sysmacros-minor.patch"
)

src_prepare() {
	default
	sed -e 's:uname -p:uname -m:g' \
		-i buildflags.mak || die
}

src_compile() {
	emake arch=x86_64 USE_PSM_UUID=1 WERROR=
}

src_install() {
	emake DESTDIR="${ED}" install
	dodoc README
	udev_dorules "${FILESDIR}"/42-infinipath-psm.rules
}
