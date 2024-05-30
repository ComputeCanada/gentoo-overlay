# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

scm="git-r3"
SRC_URI=""
EGIT_REPO_URI="git://git.whamcloud.com/fs/lustre-release.git"
if [[ $PV = *9999* ]]; then
	KEYWORDS=""
	EGIT_BRANCH="master"
else
	KEYWORDS="amd64"
	EGIT_COMMIT="2.15.3"
fi

SUPPORTED_KV_MAJOR=4
SUPPORTED_KV_MINOR=19

inherit ${scm} autotools linux-info toolchain-funcs udev flag-o-matic

DESCRIPTION="Lustre is a parallel distributed file system"
HOMEPAGE="http://wiki.whamcloud.com/"

LICENSE="GPL-2"
SLOT="0"
IUSE="client +utils modules server readline tests"

RDEPEND="
	app-alternatives/awk
	dev-libs/libnl
	readline? ( sys-libs/readline:0 )
	server? (
		>=sys-fs/zfs-kmod-0.8
		>=sys-fs/zfs-0.8
	)
"
BEPEND="${RDEPEND}
	dev-python/docutils
	virtual/linux-sources"

REQUIRED_USE="
	client? ( modules )
	server? ( modules )"

pkg_pretend() {
	KVSUPP=${SUPPORTED_KV_MAJOR}.${SUPPORTED_KV_MINOR}.x
	if kernel_is gt ${SUPPORTED_KV_MAJOR} ${SUPPORTED_KV_MINOR}; then
		eerror "Unsupported kernel version! Latest supported one is ${KVSUPP}"
		die
	fi
}

pkg_setup() {
	filter-mfpmath sse
	filter-mfpmath i386
	filter-flags -msse* -mavx* -mmmx -m3dnow

	#linux-mod_pkg_setup
	ARCH="$(tc-arch-kernel)"
	ABI="${KERNEL_ABI}"
}

src_prepare() {
	if [ ${#PATCHES[0]} -ne 0 ]; then
		eapply ${PATCHES[@]}
	fi

	eapply_user
	# replace upstream autogen.sh by our src_prepare()
	local DIRS="libcfs lnet lustre snmp"
	local ACLOCAL_FLAGS
	for dir in $DIRS ; do
		ACLOCAL_FLAGS="$ACLOCAL_FLAGS -I $dir/autoconf"
	done
	_elibtoolize -q
	eaclocal -I config $ACLOCAL_FLAGS
	eautoheader
	eautomake
	eautoconf
}

src_configure() {
	local myconf
	if use server; then
		SPL_PATH=$(basename $(echo "${EROOT}/usr/src/spl-"*)) \
			myconf="${myconf} --with-spl=${EROOT}/usr/src/${SPL_PATH} \
			--with-spl-obj=${EROOT}/usr/src/${SPL_PATH}/${KV_FULL}"
		ZFS_PATH=$(basename $(echo "${EROOT}/usr/src/zfs-"*)) \
			myconf="${myconf} --with-zfs=${EROOT}/usr/src/${ZFS_PATH} \
			--with-zfs-obj=${EROOT}/usr/src/${ZFS_PATH}/${KV_FULL}"
	fi
	econf \
		${myconf} \
		--without-ldiskfs \
		--with-linux="${KERNEL_DIR}" \
		$(use_enable client) \
		$(use_enable utils) \
		$(use_enable modules) \
		$(use_enable server) \
		$(use_enable readline) \
		$(use_enable tests) \
		--disable-iokit
}

src_compile() {
	emake CPPFLAGS="-I$PWD/lnet/include/uapi -I$PWD/libcfs/include -I$PWD/lustre/include/uapi -I$PWD/lustre/include -I$PWD/lnet/utils -DLUSTRE_VERSION_STRING=\\\"2.15.3\\\" -DHAVE_COPY_FILE_RANGE=1" CFLAGS='-Wno-error'
}

src_install() {
	emake lustreincludedir="${EPREFIX}/usr/include/linux/lustre" DESTDIR="${D}" install
	rm -r "${ED}"/{usr/bin,usr/sbin,etc} "${ED}"/usr/share/man/man[158]
	rm -r "${D}"/{etc,usr,sbin}
	#newinitd "${FILESDIR}/lnet.initd" lnet
	#newinitd "${FILESDIR}/lustre-client.initd" lustre-client
	find "${D}" -name '*.la' -delete || die
}
