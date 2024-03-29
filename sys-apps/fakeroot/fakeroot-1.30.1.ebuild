# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools flag-o-matic

DESCRIPTION="A fake root environment by means of LD_PRELOAD and SysV IPC (or TCP) trickery"
HOMEPAGE="https://packages.qa.debian.org/f/fakeroot.html"
SRC_URI="mirror://debian/pool/main/${PN:0:1}/${PN}/${P/-/_}.orig.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha arm ~arm64 ~hppa ~ia64 ppc ppc64 ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="acl debug nls test"
RESTRICT="!test? ( test )"

DEPEND="sys-libs/libcap
	acl? ( sys-apps/acl )
	test? ( app-arch/sharutils )"

DOCS=( AUTHORS BUGS DEBUG README doc/README.saving )

src_configure() {
	export ac_cv_header_sys_acl_h=$(usex acl)
	use acl || export ac_cv_search_acl_get_fd=no # bug 759568
	use debug && append-cppflags -DLIBFAKEROOT_DEBUGGING

	# https://bugs.gentoo.org/834445
	# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=101270
	filter-flags -fno-semantic-interposition

	econf --disable-static --libdir="${EPREFIX}/usr/$(get_libdir)/libfakeroot" --program-suffix="-sysv"
}

src_install() {
	default

	# no static archives
	find "${ED}" -name '*.la' -delete || die
	ln -s fakeroot-sysv "${ED}"/usr/bin/fakeroot
	ln -s faked-sysv "${ED}"/usr/bin/faked
	mv "${ED}"/usr/$(get_libdir)/libfakeroot/libfakeroot-{0,sysv}.so
	ln -s libfakeroot-sysv.so "${ED}"/usr/$(get_libdir)/libfakeroot/libfakeroot-0.so
}
