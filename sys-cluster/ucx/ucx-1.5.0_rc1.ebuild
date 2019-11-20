# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Unified Communication X"
HOMEPAGE="http://www.openucx.org"
SRC_URI="https://github.com/openucx/ucx/releases/download/v${PV/_/-}/${P/_*/}.tar.gz"

SLOT="0"
LICENSE="BSD"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
IUSE="+numa +openmp"

RDEPEND="
	numa? ( sys-process/numactl )
	sys-fabric/rdma-core
"

src_unpack() {
	unpack ${A}
	mv "${S%_*}" "$S"
}

src_configure() {
	BASE_CFLAGS="" \
	econf \
		--disable-compiler-opt \
		--enable-mt \
		--with-rdmacm="${EPREFIX}/usr" \
		--with-knem="${EPREFIX}/usr" \
		#$(use_enable numa) --enable-numa does the opposite ... \
		$(use_enable openmp)
}
