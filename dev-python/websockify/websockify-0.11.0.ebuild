# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} )

inherit distutils-r1

DESCRIPTION="WebSockets support for any application/server"
HOMEPAGE="
	https://github.com/novnc/websockify/
	https://pypi.org/project/websockify/
"
SRC_URI="
	https://github.com/novnc/websockify/archive/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="amd64 ~arm64 ~riscv x86"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"

python_prepare() {
	default
	sed -i 's/    warnings.warn/    #warnings.warn/' websockify/websocket.py
	sed -i "s@wsdir = @wsdir = \'${EPREFIX}/usr/bin\' #@" websockify/websocketproxy.py
	# This makes rebind.so compatible with glibc < 2.34
	echo 'asm(".symver dlsym, dlsym@GLIBC_2.2.5");' >> rebind.c
}

python_compile() {
	distutils-r1_python_compile
	emake rebind.so LDFLAGS="${LDFLAGS/ -Wl,-z,pack-relative-relocs/}"
}

python_install() {
	distutils-r1_python_install
	mkdir -p "${ED}"/usr/lib/websockify
	cp rebind.so "${ED}"/usr/lib/websockify
}
