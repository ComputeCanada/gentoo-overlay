# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit udev

DESCRIPTION="A framework focused on exporting fabric communication services to applications."
SRC_URI="https://github.com/ofiwg/libfabric/releases/download/v${PV}/${P}.tar.bz2"

SLOT="0"
KEYWORDS="amd64 ~x86 ~amd64-linux"
IUSE=""

DEPEND="virtual/pkgconfig"
RDEPEND="${DEPEND}
	sys-fabric/rdma-core
	sys-fabric/infinipath-psm
	sys-fabric/opa-psm2
	dev-libs/libnl"

src_configure() {
	econf --enable-psm=dl --enable-psm2=dl --enable-verbs=dl --with-libnl="${EPREFIX}/usr"
}
