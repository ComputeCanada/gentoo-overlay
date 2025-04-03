EAPI=8

PYTHON_COMPAT=( python3_{9..11} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1 optfeature pypi

DESCRIPTION="EasyBuild is a software build and installation framework."
HOMEPAGE="
	https://easybuild.io/
	https://github.com/easybuilders/easybuild
"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	~sys-cluster/easybuild-framework-${PV}[${PYTHON_USEDEP}]
	~sys-cluster/easybuild-easyblocks-${PV}[${PYTHON_USEDEP}]
	~sys-cluster/easybuild-easyconfigs-${PV}[${PYTHON_USEDEP}]
"
BDEPEND="${RDEPEND}"

pkg_postinst() {
	elog "Remember to set the module install path"
	elog "ml use \$installpath/modules/all"
	elog "where --installpath is passed to eb"

	optfeature "GitHub PR integration" dev-python/keyring dev-python/GitPython
}
