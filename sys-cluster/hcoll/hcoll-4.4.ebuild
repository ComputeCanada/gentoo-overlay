# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="FCA is a MPI-integrated software package that utilizes CORE-Direct technology for implementing the MPI collective communications."
HOMEPAGE="https://www.mellanox.com/page/products_dyn?product_family=104&menu_section=73"
SRC_URI="http://www.mellanox.com/downloads/hpc/hpc-x/v2.5/hpcx-v2.5.0-gcc-inbox-redhat7.7-x86_64.tbz"

SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND=""
RDEPEND="
	virtual/libudev
	dev-libs/libxml2
	sys-process/numactl
	sys-cluster/rdma-core
"
BDEPEND="dev-util/patchelf"

S="${WORKDIR}"

QA_PREBUILT="*"

src_install() {
	# Using doins -r would strip executable bits from all binaries
	mkdir -p "${ED}"/usr/share/doc "${ED}"/etc
	cd hpcx-v2.5.0-gcc-inbox-redhat7.7-x86_64/hcoll
	cp -pPR bin "${ED}"/usr/bin || die "Failed to copy files"
	patchelf --set-interpreter "${EPREFIX}/lib64/ld-linux-x86-64.so.2" "${ED}"/usr/bin/hcoll_info || die "patchelf failed"
	cp -pPR lib "${ED}"/usr/lib64 || die "Failed to copy files"
	rm -f "${ED}"/usr/lib64/*.la || die "Failed to delete .la files"
	cp -pPR include "${ED}"/usr/include || die "Failed to copy files"
	cp -pPR etc "${ED}"/etc/hcoll || die "Failed to copy files"
	cp -pPR share/hcoll "${ED}"/usr/share/hcoll || die "Failed to copy files"
	cp -pPR share/doc/hcoll "${ED}"/usr/share/doc/${P} || die "Failed to copy files"
	cp -pPR sdk "${ED}"/usr/share/doc/${P}/sdk || die "Failed to copy files"
}
