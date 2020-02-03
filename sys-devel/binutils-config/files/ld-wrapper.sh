#!/bin/bash

expandResponseParams() {
    local inparams=("$@")
    local n=0
    local p
    params=()
    while [ $n -lt ${#inparams[*]} ]; do
        p=${inparams[n]}
        case $p in
            @*)
                if [ -e "${p:1}" ]; then
                    args=$(<"${p:1}")
                    eval 'for arg in '${args//$/\\$}'; do params+=("$arg"); done'
                else
                    params+=("$p")
                fi
                ;;
            *)
                params+=("$p")
                ;;
        esac
        n=$((n + 1))
    done
}

set -e

# Gentoo's binutils-config sets up symbolic links as follows:
# $EPREFIX/usr/bin/ld -> x86_64-pc-linux-gnu-ld ->
# $EPREFIX/usr/x86_64-pc-linux-gnu/bin/ld -*>
# $EPREFIX/usr/x86_64-pc-linux-gnu/binutils-bin/2.32/ld
#
# This wrapper will be symlinked at the -*> as GCC's collect2
# calls $EPREFIX/usr/x86_64-pc-linux-gnu/bin/ld

EPREFIX="@GENTOO_PORTAGE_EPREFIX@"
if [[ ${EPREFIX} == "@"GENTOO_PORTAGE_EPREFIX"@" ]] ; then
	EPREFIX=""
fi
if [ -z "$EASYBUILD_CONFIGFILES" ]; then
  EASYBUILD_CONFIGFILES=/cvmfs/soft.computecanada.ca/easybuild/config.cfg
fi

path_backup="$PATH"
PATH="${EPREFIX}/usr/bin:${EPREFIX}/bin"
MACHINE=$(gcc -dumpmachine)
source "${EPREFIX}"/etc/env.d/binutils/config-$MACHINE
source "${EPREFIX}"/etc/env.d/binutils/$MACHINE-$CURRENT
LD="${EPREFIX}"/usr/${TARGET}/binutils-bin/${VER}/${0/*ld/ld}

expandResponseParams "$@"
extra=($RSNT_LDFLAGS)
extraBefore=($RSNT_LDFLAGS_BEFORE)

# This hook instructs the wrapper to only keep rpaths into
# the EasyBuild software repository

if [ "$RSNT_DONT_SET_RPATH" != 1 ]; then
    EASYBUILD_DIR=${EASYBUILD_CONFIGFILES%/*}
    EASYBUILD_RESTRICTED_DIR=${EASYBUILD_DIR/soft/restricted}
    EASYBUILD_HOME_DIR="$HOME/.local/easybuild"

    libPath=""
    addToLibPath() {
        local path="$1"
        if [ "${path:0:1}" != / ]; then return 0; fi
        case "$path" in
            *..*|*./*|*/.*|*//*)
                local path2
                if path2=$(readlink -f "$path"); then
                    path="$path2"
                fi
                ;;
        esac
        case $libPath in
            *\ $path\ *) return 0 ;;
        esac
        libPath="$libPath $path "
    }

    addToRPath() {
        # Only EASYBUILD library paths are added
        # to rpath. No /tmp, /dev/shm, etc.
        if [ "${1:0:${#EASYBUILD_DIR}}" != "$EASYBUILD_DIR" -a \
            "${1:0:${#EASYBUILD_RESTRICTED_DIR}}" != "$EASYBUILD_RESTRICTED_DIR" -a \
            "${1:0:${#EASYBUILD_HOME_DIR}}" != "$EASYBUILD_HOME_DIR" ]; then
            if [ -z "$origin_rpath" -a \
		"$RSNT_EASYBUILD_MAGIC_COOKIE" == "263ca73bb634185aab1d1b41627fdbba" ]; then
		# when inside easybuild only,
		# heuristically add ORIGIN locations only if library location unaccounted,
		# mostly likely in some build directory
                rpath="$rpath \$ORIGIN \$ORIGIN/../lib \$ORIGIN/../lib64"
		origin_rpath="added"
	    fi
            return 0
        fi
        # also exclude stub libraries like for CUDA
        if [ "${1%%/stubs}" != "$1" ]; then
            return 0
        fi
	# check if soft equivalent exists for restricted
	rpath_to_add=$1
        if [ "${1:0:${#EASYBUILD_RESTRICTED_DIR}}" == "$EASYBUILD_RESTRICTED_DIR" -a \
	    -d "$EASYBUILD_DIR${1:${#EASYBUILD_RESTRICTED_DIR}}" ]; then
	    rpath_to_add="$EASYBUILD_DIR${1:${#EASYBUILD_RESTRICTED_DIR}}"
        fi
        case $rpath in
            *\ $rpath_to_add\ *) return 0 ;;
        esac
        rpath="$rpath $rpath_to_add "
    }

    libs=""
    addToLibs() {
        libs="$libs $1"
    }

    rpath=''
    origin_rpath=''

    # First, find all -L... switches.
    allParams=("${params[@]}" ${extra[@]})
    n=0
    static=0
    while [ $n -lt ${#allParams[*]} ]; do
        p=${allParams[n]}
        p2=${allParams[$((n+1))]}
        if [ "${p:0:3}" = -L/ ]; then
            addToLibPath ${p:2}
        elif [ "$p" = -L ]; then
            addToLibPath ${p2}
            n=$((n + 1))
        elif [ "$p" = -l -a $static = 0 ]; then
            addToLibs ${p2}
            n=$((n + 1))
        elif [ "${p:0:2}" = -l -a $static = 0 ]; then
            addToLibs ${p:2}
        elif [ "$p" = -Bstatic ]; then
	    static=1
        elif [ "$p" = -Bdynamic ]; then
	    static=0
        elif [ "$p" = -dynamic-linker ]; then
            # Ignore the dynamic linker argument, or it
            # will get into the next 'elif'. We don't want
            # the dynamic linker path rpath to go always first.
            n=$((n + 1))
        elif [[ "$p" =~ ^[^-].*\.so($|\.) ]]; then
            # This is a direct reference to a shared library, so add
            # its directory to the rpath.
            path="$(dirname "$p")";
            addToRPath "${path}"
        fi
        n=$((n + 1))
    done

    # Second, for each directory in the library search path (-L...),
    # see if it contains a dynamic library used by a -l... flag.  If
    # so, add the directory to the rpath.
    # It's important to add the rpath in the order of -L..., so
    # the link time chosen objects will be those of runtime linking.

    unset FOUNDLIBS
    declare -A FOUNDLIBS
    for i in $libPath; do
	for j in $libs; do
	    foundlib=${FOUNDLIBS["$j"]}
            if [ -z "$foundlib" -a -f "$i/lib$j.so" ]; then
                addToRPath $i
		break
            fi
	done
	for j in $libs; do
	    foundlib=${FOUNDLIBS["$j"]}
            if [ -z "$foundlib" -a -f "$i/lib$j.so" ]; then
		FOUNDLIBS["$j"]=1
            fi
	done
    done


    # Finally, add `-rpath' switches.
    for i in $rpath; do
        extra+=(-rpath $i)
    done
    # use RPATH, not RUNPATH
    if [ -n "$rpath" ]; then
	extra+=(--disable-new-dtags)
    fi
fi

# Optionally print debug info.
if [ -n "$RSNT_DEBUG" ]; then
  echo "original flags to $LD:" >&2
  for i in "${params[@]}"; do
      echo "  $i" >&2
  done
  echo "extra flags to $LD:" >&2
  for i in ${extra[@]}; do
      echo "  $i" >&2
  done
fi

PATH="$path_backup"
exec $LD ${extraBefore[@]} "${params[@]}" ${extra[@]}
