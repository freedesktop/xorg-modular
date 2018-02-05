#!/bin/bash
# configure script adapter for Meson
# Based on build-api: https://github.com/cgwalters/build-api
# Copyright 2010, 2011, 2013 Colin Walters <walters@verbum.org>
# Copyright 2016, 2017 Emmanuele Bassi
# Licensed under the new-BSD license (http://www.opensource.org/licenses/bsd-license.php)

# Build API variables:

# Little helper function for reading args from the commandline.
# it automatically handles -a b and -a=b variants, and returns 1 if
# we need to shift $3.
read_arg() {
    # $1 = arg name
    # $2 = arg value
    # $3 = arg parameter
    local rematch='^[^=]*=(.*)$'
    if [[ $2 =~ $rematch ]]; then
	read "$1" <<< "${BASH_REMATCH[1]}"
    else
	read "$1" <<< "$3"
	# There is no way to shift our callers args, so
	# return 1 to indicate they should do it instead.
	return 1
    fi
}

sanitycheck() {
    # $1 = arg name
    # $1 = arg command
    # $2 = arg alternates
    local cmd=$( which $2 2>/dev/null )

    if [ -x "$cmd" ]; then
        read "$1" <<< "$cmd"
        return 0
    fi

    test -z $3 || {
        for alt in $3; do
            cmd=$( which $alt 2>/dev/null )

            if [ -x "$cmd" ]; then
                read "$1" <<< "$cmd"
                return 0
            fi
        done
    }

    echo -e "\e[1;31mERROR\e[0m: Command '$2' not found"
    exit 1
}

sanitycheck MESON 'meson'
sanitycheck NINJA 'ninja' 'ninja-build'

while (($# > 0)); do
    case "${1%%=*}" in
	--prefix) read_arg prefix "$@" || shift;;
	--bindir) read_arg bindir "$@" || shift;;
	--sbindir) read_arg sbindir "$@" || shift;;
	--libexecdir) read_arg libexecdir "$@" || shift;;
	--datarootdir) read_arg datarootdir "$@" || shift;;
	--datadir) read_arg datadir "$@" || shift;;
	--sysconfdir) read_arg sysconfdir "$@" || shift;;
	--libdir) read_arg libdir "$@" || shift;;
	--mandir) read_arg mandir "$@" || shift;;
	--includedir) read_arg includedir "$@" || shift;;
	*) echo -e "\e[1;33mINFO\e[0m: Ignoring unknown option '$1'";;
    esac
    shift
done

# Defaults
test -z ${prefix} && prefix="/usr/local"
test -z ${bindir} && bindir=${prefix}/bin
test -z ${sbindir} && sbindir=${prefix}/sbin
test -z ${libexecdir} && libexecdir=${prefix}/bin
test -z ${datarootdir} && datarootdir=${prefix}/share
test -z ${datadir} && datadir=${datarootdir}
test -z ${sysconfdir} && sysconfdir=${prefix}/etc
test -z ${libdir} && libdir=${prefix}/lib
test -z ${mandir} && mandir=${prefix}/share/man
test -z ${includedir} && includedir=${prefix}/include

# The source directory is the location of this file
srcdir=$(dirname $0)

# The build directory is the current location
builddir=`pwd`

# If we're calling this file from the source directory then
# we automatically create a build directory and ensure that
# both Meson and Ninja invocations are relative to that
# location
if [[ -f "${builddir}/meson.build" ]]; then
  mkdir -p _build
  builddir="${builddir}/_build"
  NINJA_OPT="-C ${builddir}"
fi

# Wrapper Makefile for Ninja
cat > Makefile <<END
# Generated by configure; do not edit

all:
	CC="\$(CC)" CXX="\$(CXX)" ${NINJA} ${NINJA_OPT}

install:
	DESTDIR="\$(DESTDIR)" ${NINJA} ${NINJA_OPT} install

check:
	${MESON} test ${NINJA_OPT}
END

echo "Summary:"
echo "  meson:....... ${MESON}"
echo "  ninja:....... ${NINJA}"
echo "  prefix:...... ${prefix}"
echo "  bindir:...... ${bindir}"
echo "  sbindir:..... ${sbindir}"
echo "  libexecdir:.. ${libexecdir}"
echo "  datarootdir:. ${datarootdir}"
echo "  datadir:..... ${datadir}"
echo "  sysconfdir:.. ${sysconfdir}"
echo "  libdir:...... ${libdir}"
echo "  mandir:...... ${mandir}"
echo "  includedir:.. ${includedir}"

exec ${MESON} \
	--prefix=${prefix} \
	--libdir=${libdir} \
	--libexecdir=${libexecdir} \
	--datadir=${datadir} \
	--sysconfdir=${sysconfdir} \
	--bindir=${bindir} \
	--includedir=${includedir} \
	--mandir=${mandir} \
	--default-library shared \
	${builddir} \
	${srcdir}

# vim: ai ts=8 noet sts=2 ft=sh
