# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="OpenIB library provides the API for use interfacing with IB management programs"
SRC_URI="https://www.openfabrics.org/downloads/management/${P}.tar.gz"

SLOT="0"
KEYWORDS="amd64 ~x86 ~amd64-linux"
IUSE=""

DEPEND="
	sys-fabric/rdma-core:${SLOT}
	"
RDEPEND="${DEPEND}"
