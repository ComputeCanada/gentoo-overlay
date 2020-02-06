# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Only builds libpmi and libpmi2 for OpenMPI builds

EAPI=7

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
		MY_PV=$(ver_rs 1-3 '-') # stable releases
	fi
	MY_P="slurm-${MY_PV}"
	INHERIT_GIT=""
	SRC_URI="https://github.com/SchedMD/slurm/archive/${MY_P}.tar.gz"
	KEYWORDS="amd64 ~x86"
fi

inherit autotools prefix toolchain-funcs ${INHERIT_GIT}

DESCRIPTION="A Highly Scalable Resource Manager"
HOMEPAGE="https://www.schedmd.com https://github.com/SchedMD/slurm"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

S="${WORKDIR}/slurm-${MY_P}"

src_unpack() {
	if [[ ${PV} == *9999* ]]; then
		git-r3_src_unpack
	else
		default
	fi
}

src_configure() {
	econf --without-lz4 --without-rpath
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
