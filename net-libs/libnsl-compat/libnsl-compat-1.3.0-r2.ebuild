# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit multilib-minimal

DESCRIPTION="Public client interface for NIS(YP) and NIS+ in a IPv6 ready version"
HOMEPAGE="https://github.com/thkukuk/libnsl"
SRC_URI="https://github.com/thkukuk/libnsl/releases/download/v${PV}/libnsl-${PV}.tar.xz"

SLOT="0/2"
LICENSE="LGPL-2.1+ BSD"

# Stabilize together with glibc-2.26!
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"

IUSE="static-libs"

DEPEND="
	>=net-libs/libtirpc-1.2.0:=[${MULTILIB_USEDEP}]
"
RDEPEND="${DEPEND}
	!<sys-libs/glibc-2.26
"

PATCHES=(
	"${FILESDIR}"/libnsl-1.3.0-rpath.patch
)
S="${WORKDIR}/libnsl-1.3.0"

multilib_src_configure() {
	local myconf=(
		--enable-shared
		$(use_enable static-libs static)
	)
	ECONF_SOURCE=${S} econf "${myconf[@]}"
}

multilib_src_compile() {
	emake -C src libnsl.la
}

multilib_src_install() {
	newlib.so src/.libs/libnsl.so.2.* libnsl.so.2
}
