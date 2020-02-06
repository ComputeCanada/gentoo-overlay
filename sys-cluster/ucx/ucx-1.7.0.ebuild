# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Unified Communication X"
HOMEPAGE="http://www.openucx.org"
SRC_URI="https://github.com/openucx/ucx/releases/download/v${PV}/${P}.tar.gz"

SLOT="0"
LICENSE="BSD"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
IUSE="+numa +openmp"

RDEPEND="
	sys-libs/binutils-libs:=
	sys-cluster/rdma-core
	sys-cluster/knem
	numa? ( sys-process/numactl )
"
DEPEND="${RDEPEND}"

src_configure() {
	BASE_CFLAGS="" \
	econf \
		--disable-logging \
		--disable-debug \
		--disable-assertions \
		--disable-params-check \
		--disable-optimizations \
		--enable-mt \
		--without-cm \
		--disable-compiler-opt \
		--with-rdmacm="${EPREFIX}/usr" \
		--with-verbs="${EPREFIX}/usr" \
		--with-knem="${EPREFIX}/usr" \
		$(use_enable numa) \
		$(use_enable openmp)
}

src_compile() {
	BASE_CFLAGS="" emake
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die
}
