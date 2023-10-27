# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MY_P="Linux-PAM-${PV}"

# Avoid QA warnings
# Can reconsider w/ EAPI 8 and IDEPEND, bug #810979
TMPFILES_OPTIONAL=1

inherit db-use fcaps flag-o-matic toolchain-funcs usr-ldscript multilib-minimal

DESCRIPTION="Linux-PAM (Pluggable Authentication Modules)"
HOMEPAGE="https://github.com/linux-pam/linux-pam"
SRC_URI="
	https://github.com/linux-pam/linux-pam/releases/download/v${PV}/${MY_P}.tar.xz
	https://github.com/linux-pam/linux-pam/releases/download/v${PV}/${MY_P}-docs.tar.xz
"
S="${WORKDIR}/${MY_P}"

LICENSE="|| ( BSD GPL-2 )"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="audit berkdb debug nis selinux"

BDEPEND="
	app-alternatives/yacc
	dev-libs/libxslt
	sys-devel/flex
	sys-devel/gettext
	virtual/pkgconfig
"
DEPEND="
	virtual/libcrypt:=[${MULTILIB_USEDEP}]
	>=virtual/libintl-0-r1[${MULTILIB_USEDEP}]
	audit? ( >=sys-process/audit-2.2.2[${MULTILIB_USEDEP}] )
	berkdb? ( >=sys-libs/db-4.8.30-r1:=[${MULTILIB_USEDEP}] )
	selinux? ( >=sys-libs/libselinux-2.2.2-r4[${MULTILIB_USEDEP}] )
	nis? (
		net-libs/libnsl:=[${MULTILIB_USEDEP}]
		>=net-libs/libtirpc-0.2.4-r2:=[${MULTILIB_USEDEP}]
	)
"
RDEPEND="${DEPEND}"

src_prepare() {
	default
	touch ChangeLog || die
}

multilib_src_configure() {
	# Do not let user's BROWSER setting mess us up, bug #549684
	unset BROWSER

	# This whole weird has_version libxcrypt block can go once
	# musl systems have libxcrypt[system] if we ever make
	# that mandatory. See bug #867991.
	if use elibc_musl && ! has_version sys-libs/libxcrypt[system] ; then
		# Avoid picking up symbol-versioned compat symbol on musl systems
		export ac_cv_search_crypt_gensalt_rn=no

		# Need to avoid picking up the libxcrypt headers which define
		# CRYPT_GENSALT_IMPLEMENTS_AUTO_ENTROPY.
		cp "${ESYSROOT}"/usr/include/crypt.h "${T}"/crypt.h || die
		append-cppflags -I"${T}"
	fi

	local myconf=(
		CC_FOR_BUILD="$(tc-getBUILD_CC)"
		--with-db-uniquename=-$(db_findver sys-libs/db)
		--with-xml-catalog="${EPREFIX}"/etc/xml/catalog
		--enable-securedir="${EPREFIX}"/$(get_libdir)/security
		--includedir="${EPREFIX}"/usr/include/security
		--libdir="${EPREFIX}"/usr/$(get_libdir)
		--enable-pie
		--enable-unix
		--disable-prelude
		--disable-doc
		--disable-regenerate-docu
		--disable-static
		--disable-Werror
		# TODO: wire this up now it's more useful as of 1.5.3
		--disable-econf

		# TODO: add elogind support
		# lastlog is enabled again for now by us until logind support
		# is handled. Even then, disabling lastlog will probably need
		# a news item.
		--disable-logind
		--enable-lastlog

		$(use_enable audit)
		$(use_enable berkdb db)
		$(use_enable debug)
		$(use_enable nis)
		$(use_enable selinux)
		--enable-isadir='.' # bug #464016
	)
	ECONF_SOURCE="${S}" econf "${myconf[@]}"
}

multilib_src_compile() {
	emake sepermitlockdir="${EPREFIX}/run/sepermit" -C libpam
}

multilib_src_install() {
	dolib.so libpam/.libs/libpam.so.0*
}
