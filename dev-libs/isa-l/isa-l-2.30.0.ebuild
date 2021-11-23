# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit autotools-utils

DESCRIPTION="Intel Intelligent Storage Acceleration Library, Open Source Version"
HOMEPAGE="https://01.org/intel%C2%AE-storage-acceleration-library-open-source-version/ https://github.com/01org/isa-l"
SRC_URI="https://github.com/01org/isa-l/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD-3"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="|| ( dev-lang/yasm dev-lang/nasm )"
RDEPEND=""

AUTOTOOLS_AUTORECONF=1
DOCS=( "Release_notes.txt" )

src_prepare()	{
	sed -i "s/{D}/{DD}/g" Makefile.am || die "sed failed"
	autotools-utils_src_prepare
}

src_test()	{
	ewarn "\n\n\n Warning, tests take a lot of time\n\n\n"
	sleep 5
	autotools-utils_src_test
}
