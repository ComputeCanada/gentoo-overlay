# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )

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
KEYWORDS="amd64 ~arm64 ~riscv ~x86"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="
	dev-python/jwcrypto[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/simplejson[${PYTHON_USEDEP}]
	dev-python/redis[${PYTHON_USEDEP}]
"

python_prepare() {
	default
	sed -i 's/    warnings.warn/    #warnings.warn/' websockify/websocket.py
	sed -i "s@wsdir = @wsdir = \'${EPREFIX}/usr/bin\' #@" websockify/websocketproxy.py
}

python_compile() {
	distutils-r1_python_compile
	emake rebind.so
}

python_install() {
	distutils-r1_python_install
	mkdir -p "${ED}"/usr/lib/websockify
	cp rebind.so "${ED}"/usr/lib/websockify
}
