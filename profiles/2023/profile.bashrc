if [[ ${CATEGORY}/${PN} == sys-libs/glibc && ${EBUILD_PHASE} == configure ]]; then
    cd "${S}"
    einfo "Deprefixifying hardcoded path for /etc and /var"

    for f in libio/iopopen.c \
		 shadow/lckpwdf.c resolv/{netdb,resolv}.h elf/rtld.c \
		 nis/nss_compat/compat-{grp,initgroups,{,s}pwd}.c \
		 nss/{bug-erange,nss_files/files-{XXX,init{,groups}}}.c \
		 sysdeps/{{generic,unix/sysv/linux}/paths.h,posix/system.c}
    do
	ebegin "  Updating $f"
	sed -i -r "s,([:\"])${EPREFIX}/(etc|var),\1/\2,g" $f
	eend $?
    done
fi
