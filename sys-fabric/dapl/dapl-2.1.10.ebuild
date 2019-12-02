# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="OpenIB - Direct Access Provider Library"
SRC_URI="https://www.openfabrics.org/downloads/dapl/${P}.tar.gz"

SLOT="0"
KEYWORDS="amd64 ~x86 ~amd64-linux"
IUSE=""

DEPEND="sys-cluster/rdma-core
	sys-fabric/libscif"
RDEPEND="${DEPEND}
		!sys-fabric/openib-userspace"
