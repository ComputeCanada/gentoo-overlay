# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit udev

DESCRIPTION="OpenIB userspace driver for the PathScale InfiniBand HCAs"
SRC_URI="https://github.com/intel/${PN}/archive/PSM2_${PV}.tar.gz -> {P}.tar.gz"

SLOT="0"
KEYWORDS="amd64 ~x86 ~amd64-linux"
IUSE=""

DEPEND="virtual/pkgconfig"
RDEPEND="${DEPEND}
	sys-apps/util-linux
	sys-process/numactl
	virtual/udev"

S="${WORKDIR}/${PN}-PSM2_${PV}"

PATCHES=(
	"${FILESDIR}/${PN}-fix-silent-data-error.patch"
)

src_compile() {
	emake arch=x86_64 USE_PSM_UUID=1 WERROR=
}

src_install() {
	emake arch=x86_64 UDEVDIR="/lib/udev" DESTDIR="${D}/${EPREFIX}" install
	mv "${D}/${EPREFIX}"/usr/lib64/libpsm2.so.2.1{,.1}
	ln -sf libpsm2.so.2.1.1 "${D}/${EPREFIX}"/usr/lib64/libpsm2.so.2
	dodoc README
}
