# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{6,7} )

inherit distutils-r1

SRC_URI="https://github.com/kanaka/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
DESCRIPTION="WebSockets support for any application/server"
HOMEPAGE="https://github.com/kanaka/websockify"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="amd64 ~arm64 x86"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"

python_prepare() {
	default
	sed -i 's/install_requires/#install_requires/' setup.py
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
