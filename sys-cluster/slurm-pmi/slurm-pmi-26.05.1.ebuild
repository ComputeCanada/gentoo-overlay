# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Only builds libpmi and libpmi2 for OpenMPI builds

EAPI=8

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/SchedMD/slurm.git"
	INHERIT_GIT="git-r3"
	SRC_URI=""
	KEYWORDS=""
	MY_P="${P}"
else
	if [[ ${PV} == *pre* || ${PV} == *rc* ]]; then
		MY_PV=$(ver_rs '-0.') # pre-releases or release-candidate
	else
		MY_PV=$(ver_rs 1-4 '-') # stable releases
	fi
	MY_P="slurm-${PV}"
	INHERIT_GIT=""
	SRC_URI="https://download.schedmd.com/slurm/${MY_P}.tar.bz2"
	KEYWORDS="amd64 ~arm64 ~riscv ~x86"
fi

inherit autotools prefix toolchain-funcs ${INHERIT_GIT}

DESCRIPTION="A Highly Scalable Resource Manager"
HOMEPAGE="https://www.schedmd.com https://github.com/SchedMD/slurm"

LICENSE="GPL-2"
SLOT="0"
IUSE="+munge"

S="${WORKDIR}/${MY_P}"

COMMON_DEPEND="
	munge? ( sys-auth/munge )
	app-arch/lz4:0=
	dev-libs/glib:2="

DEPEND="${COMMON_DEPEND}"

RDEPEND="${COMMON_DEPEND}"

src_unpack() {
	if [[ ${PV} == *9999* ]]; then
		git-r3_src_unpack
	else
		default
	fi
}

src_prepare() {
	default
	hprefixify auxdir/x_ac_{lz4,ofed,munge}.m4
	eautoreconf
}

src_configure() {
	econf --without-rpath --with-munge="${EPREFIX}/usr"
}

src_compile() {
	default
	#emake LIB_SLURM="../../src/api/.libs/libslurm.a" -C contribs/pmi
	emake -C contribs/pmi2
}

src_install() {
	#emake DESTDIR="${D}" -C contribs/pmi install
	#insinto /usr/include/slurm
	#doins slurm/pmi.h
	emake DESTDIR="${D}" -C contribs/pmi2 install
	find "${D}" -name '*.la' -delete || die
}
