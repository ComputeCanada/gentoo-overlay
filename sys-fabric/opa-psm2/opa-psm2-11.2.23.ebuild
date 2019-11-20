# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit udev

DESCRIPTION="OpenIB userspace driver for the PathScale InfiniBand HCAs"
SRC_URI="https://github.com/01org/opa-psm2/archive/IFS_RELEASE_10_8_0_0_204.tar.gz"

SLOT="0"
KEYWORDS="amd64 ~x86 ~amd64-linux"
IUSE=""

DEPEND="virtual/pkgconfig"
RDEPEND="${DEPEND}
	sys-apps/util-linux
	sys-process/numactl
	virtual/udev"

src_unpack() {
	default
	mv "${PN}-"* "${S}"
}

src_compile() {
	emake arch=x86_64 USE_PSM_UUID=1 WERROR=
}

src_install() {
	emake arch=x86_64 UDEVDIR="/lib/udev" DESTDIR="${D}/${EPREFIX}" install
	dodoc README
}
