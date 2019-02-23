#!/bin/sh
# ===========================================================================
#
# NAME
#   build.sh - extract, configure, build and install the X Window System
#
# SYNOPSIS
#   build.sh [options] [prefix]
#   build.sh [-L]
#
# DESCRIPTION
#   The script ultimate goal is to build all of the X Window and some of its
#   dependencies from source.
#
#   X.Org Modular Tree Developer's Guide
#
#   Please consult the guide at http://www.x.org/wiki/ModularDevelopersGuide
#   It provides detailed instructions on the build tools to install, where to
#   find the script and how to invoke it.
#
#   The X Window System Source Code
#
#   The source code is hosted by freedesktop.org and is composed of over 200
#   modules under the git source code management system. X.Org releases are
#   available at http://www.x.org/releases/ in the form of software packages.
#
#   Basic Operation
#
#   The script goes through its list of modules to build. If the source code is
#   not on disk, it attempts to obtain it from git if the --clone option is
#   specified. If not, it looks for a package archive file on disk. If it is
#   still not found, the module is skipped.
#
#   The script then runs the appropriate configure script, either autogen.sh
#   for git modules or the autoconf generated configure script for package
#   archives.
#
# FEATURES
#   Over time, functionality have been added to help building a large
#   number modules. Progress report, handling build breaks, supporting the
#   GNU Build System features, final build report, and so on.
#
#   Building from a Custom Modules List
#
#   Starting from the list generated using the -L option, remove unwanted
#   modules. You may also add your own module or add specific configure
#   options for some modules to meet your configuration needs. Using the
#   --modfile option, your list replaces the built-in list of the script.
#
#   Resuming Build After a Break
#
#   The script can resume building at the last point of failure. This saves a
#   lot of build time as the modules already built are skipped. The --autoresume
#   option can be used with --modfile such that only the modules you care about
#   are built and revisited until successful completion.
#
#   Specifying Custom Build Commands
#
#   By default, the script invokes the make program with the target "all" and
#   "install". Some options like -c, -D, or -d alter the targets the make
#   program builds, but you can specify your own command instead. Using the
#   --cmd option, provide a different make or git command.
#
#   Specifying Configuration Options to Specific Modules
#
#   In the modulesfile used by the --modfile option, add any configuration
#   options you want to pass to the modules as it gets configures by autoconf.
#   Write the configure options next to the module name in the file.
#   It could be something like --enable-strict-compilation for example.
#
# OPTIONS
#   -a          Do NOT run auto config tools (autogen.sh, configure)
#   -b          Use .build.unknown build directory
#   -c          Run make clean in addition to "all install"
#   -D          Run make dist in addition to "all install"
#   -d          Run make distcheck in addition "all install"
#   -g          Compile and link with debug information
#   -L          Just list modules to build
#   -m          Do NOT run any of the make targets
#   -h, --help  Display this help and exit successfully
#   -n          Do not quit after error; just print error message
#   -o module/component
#               Build just this module/component
#   -p          Update source code before building (git pull --rebase)
#   -s sudo   The command name providing superuser privilege
#   --autoresume resumefile
#               Append module being built to, and autoresume from, resumefile
#   --check     Run make check in addition "all install"
#   --clone     Clone non-existing repositories (uses \$GITROOT if set)
#   --cmd command
#               Execute arbitrary git, gmake, or make command
#   --confflags options
#               Pass options to autgen.sh/configure of all modules
#   --modfile modulesfile
#               Only process the module/components specified in modulesfile
#               Any text after, and on the same line as, the module/component
#               is assumed to be configuration options for the configuration
#               of each module/component specifically
#   --retry-v1  Remake 'all' on failure with Automake silent rules disabled
#
# PREFIX
#   An absolute filename where GNU "make" will install binaries, libraries and
#   other installable files. The value is passed to Autoconf through the
#   --prefix option.
#
# FILES
#   resumefile
#   When using --autoresume, the script reads and skips modules tagged with
#   "PASS" and resume building at the module tagged with "FAIL". The resumefile
#   file is not intended to be user edited.
#
#   modulesfile
#   When using --modfile, the script replaces its internal modules list with
#   the list contained in the file. This allows you to build only the modules
#   you care about and to add third party modules or modules you create.
#   It is helpful to initialized the file using the -L option.#
#
# ENVIRONMENT
#   Environment variables specific to build.sh:
#
#   PREFIX      Install architecture-independent files in PREFIX [/usr/local]
#               Each module/components is invoked with --prefix
#   EPREFIX     Install architecture-dependent files in EPREFIX [PREFIX]
#               Each module/components is invoked with --exec-prefix
#   BINDIR      Install user executables [EPREFIX/bin]
#               Each module/components is invoked with --bindir
#   DATAROOTDIR Install read-only arch-independent data root [PREFIX/share]
#               Each module/components is invoked with --datarootdir
#   DATADIR     Install read-only architecture-independent data [DATAROOTDIR]
#               Each module/components is invoked with --datadir
#   LIBDIR      Install object code libraries [EPREFIX/lib]
#               Each module/components is invoked with --libdir
#   LOCALSTATEDIR
#               Modifiable single-machine data [PREFIX/var]
#               Each module/components is invoked with --localstatedir
#   QUIET       Do not print messages saying which checks are being made
#               Each module/components is invoked with --quite
#   GITROOT     Source code repository path [git://anongit.freedesktop.org/git]
#               Optional when using --clone to update source code before building
#   GITCLONEOPTS Options passed to git clone.
#               Optional when using --clone to update source code before building
#   CONFFLAGS   Configure options to pass to all Autoconf configure scripts
#               Refer to 'configure --help' from any module/components
#
#  Environment variables defined by the GNU Build System:
#
#  ACLOCAL     The aclocal cmd name [aclocal -I ${DESTDIR}/${DATADIR}/aclocal]
#  DESTDIR     Path to the staging area where installed objects are relocated
#  MAKE        The name of the make command [make]
#  MAKEFLAGS   Options to pass to all $(MAKE) invocations
#  CC          C compiler command
#  CFLAGS      C compiler flags
#  LDFLAGS     linker flags, e.g. -L<lib dir> if you have libraries in a
#              nonstandard directory <lib dir>
#  CPPFLAGS    C/C++/Objective C preprocessor flags, e.g. -I<include dir> if
#              you have headers in a nonstandard directory <include dir>
#  CPP         C preprocessor
#
#  Environment variables defined by the shell:
#  PATH        List of directories that the shell searches for commands
#              $DESTDIR/$BINDIR is prepended
#
#  Environment variables defined by the dynamic linker:
#  LD_LIBRARY_PATH
#              List directories that the linker searches for shared objects
#              $DESTDIR/$LIBDIR is prepended
#
#  Environment variables defined by the pkg-config system:
#
#  PKG_CONFIG_PATH
#              List directories that pkg-config searches for libraries
#              $DESTDIR/$DATADIR/pkgconfig and
#              $DESTDIR/$LIBDIR/pkgconfig are prepended
#
# PORTABILITY
#  This script is intended to run on any platform supported by X.Org.
#  The script must be able to run in a Bourne shell.
#
# ===========================================================================

envoptions() {
cat << EOF
Environment variables specific to build.sh:
  PREFIX      Install architecture-independent files in PREFIX [/usr/local]
              Each module/components is invoked with --prefix
  EPREFIX     Install architecture-dependent files in EPREFIX [PREFIX]
              Each module/components is invoked with --exec-prefix
  BINDIR      Install user executables [EPREFIX/bin]
              Each module/components is invoked with --bindir
  DATAROOTDIR Install read-only arch-independent data root [PREFIX/share]
              Each module/components is invoked with --datarootdir
  DATADIR     Install read-only architecture-independent data [DATAROOTDIR]
              Each module/components is invoked with --datadir
  LIBDIR      Install object code libraries [EPREFIX/lib]
              Each module/components is invoked with --libdir
  LOCALSTATEDIR
              Modifiable single-machine data [PREFIX/var]
              Each module/components is invoked with --localstatedir
  QUIET       Do not print messages saying which checks are being made
              Each module/components is invoked with --quite
  GITROOT     Source code repository path [git://anongit.freedesktop.org/git]
              Optional when using --clone to update source code before building
  CONFFLAGS   Configure options to pass to all Autoconf configure scripts
              Refer to 'configure --help' from any module/components

Environment variables defined by the GNU Build System:
  ACLOCAL     The aclocal cmd name [aclocal -I \${DESTDIR}/\${DATADIR}/aclocal]
  DESTDIR     Path to the staging area where installed objects are relocated
  MAKE        The name of the make command [make]
  MAKEFLAGS   Options to pass to all \$(MAKE) invocations
  CC          C compiler command
  CFLAGS      C compiler flags
  LDFLAGS     linker flags, e.g. -L<lib dir> if you have libraries in a
              nonstandard directory <lib dir>
  CPPFLAGS    C/C++/Objective C preprocessor flags, e.g. -I<include dir> if
              you have headers in a nonstandard directory <include dir>
  CPP         C preprocessor

Environment variables defined by the shell:
  PATH        List of directories that the shell searches for commands
              \$DESTDIR/\$BINDIR is prepended

Environment variables defined by the dynamic linker:
  LD_LIBRARY_PATH
              List directories that the linker searches for shared objects
              \$DESTDIR/\$LIBDIR is prepended

Environment variables defined by the pkg-config system:
  PKG_CONFIG_PATH
              List directories that pkg-config searches for libraries
              \$DESTDIR/\$DATADIR/pkgconfig and
              \$DESTDIR/\$LIBDIR/pkgconfig are prepended
EOF
}

setup_buildenv() {

    # Remember if the user had supplied a value through env var or cmd line
    # A value from cmd line takes precedence of the shell environment
    PREFIX_USER=${PREFIX:+yes}
    EPREFIX_USER=${EPREFIX:+yes}
    BINDIR_USER=${BINDIR:+yes}
    DATAROOTDIR_USER=${DATAROOTDIR:+yes}
    DATADIR_USER=${DATADIR:+yes}
    LIBDIR_USER=${LIBDIR:+yes}
    LOCALSTATEDIR_USER=${LOCALSTATEDIR:+yes}

    # Assign a default value if no value was supplied by the user
    PREFIX=${PREFIX:-/usr/local}
    EPREFIX=${EPREFIX:-$PREFIX}
    BINDIR=${BINDIR:-$EPREFIX/bin}
    DATAROOTDIR=${DATAROOTDIR:-$PREFIX/share}
    DATADIR=${DATADIR:-$DATAROOTDIR}
    LIBDIR=${LIBDIR:-$EPREFIX/lib}
    LOCALSTATEDIR=${LOCALSTATEDIR:-$PREFIX/var}

    # Support previous usage of LIBDIR which was a subdir relative to PREFIX
    # We use EPREFIX as this is what PREFIX really meant at the time
    if [ X"$LIBDIR" != X ]; then
	if [ X"`expr $LIBDIR : "\(.\)"`" != X/ ]; then
	    echo ""
	    echo "Warning: this usage of \$LIBDIR is deprecated. Use a full path name."
	    echo "The supplied value \"$LIBDIR\" has been replaced with $EPREFIX/$LIBDIR."
	    echo ""
		LIBDIR=$EPREFIX/$LIBDIR
	fi
    fi

    # All directories variables must be full path names
    check_full_path $PREFIX PREFIX
    check_full_path $EPREFIX EPREFIX
    check_full_path $BINDIR BINDIR
    check_full_path $DATAROOTDIR DATAROOTDIR
    check_full_path $DATADIR DATADIR
    check_full_path $LIBDIR LIBDIR
    check_full_path $LOCALSTATEDIR LOCALSTATEDIR

    # This will catch the case where user forgets to set PREFIX
    # and does not have write permission in the /usr/local default location
    check_writable_dir ${DESTDIR}${PREFIX} PREFIX

    # Must create local aclocal dir or aclocal fails
    ACLOCAL_LOCALDIR="${DESTDIR}${DATADIR}/aclocal"
    $SUDO mkdir -p ${ACLOCAL_LOCALDIR}

    # The following is required to make aclocal find our .m4 macros
    ACLOCAL=${ACLOCAL:="aclocal"}
    ACLOCAL="${ACLOCAL} -I ${ACLOCAL_LOCALDIR}"
    export ACLOCAL

    # The following is required to make pkg-config find our .pc metadata files
    PKG_CONFIG_PATH=${DESTDIR}${DATADIR}/pkgconfig:${DESTDIR}${LIBDIR}/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}
    export PKG_CONFIG_PATH

    # Set the library path so that locally built libs will be found by apps
    LD_LIBRARY_PATH=${DESTDIR}${LIBDIR}${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}
    export LD_LIBRARY_PATH

    # Set the path so that locally built apps will be found and used
    PATH=${DESTDIR}${BINDIR}${PATH+:$PATH}
    export PATH

    # Choose which make program to use
    MAKE=${MAKE:="make"}

    # Create the log file directory
    $SUDO mkdir -p ${DESTDIR}${LOCALSTATEDIR}/log
}

# explain where a failure occurred
# if you find this message in the build output it can help tell you where the failure occurred
# arguments:
#   $1 - which command failed
#   $2 - module
#   $3 - component
# returns:
#   (irrelevant)
failed() {
    cmd=$1
    module=$2
    component=$3
    echo "build.sh: \"$cmd\" failed on $module${component:+/}$component"
    failed_components="$failed_components $module${component:+/}$component"
}

# print a pretty title to separate the processing of each module
# arguments:
#   $1 - module
#   $2 - component
#   $3 - configuration options
# returns:
#   (irrelevant)
module_title() {
    module=$1
    component=$2
    confopts="$3"
    # preconds
    if [ X"$module" = X ]; then
	return
    fi

    echo ""
    echo "======================================================================"
    echo "==  Processing:  \"$module${component:+/}$component\""
    echo "==        configuration options:  $CONFFLAGS $confopts"
}

# Search for tarballs in either cwd or under a module directory
# The tarball is always extracted in either one of these locations:
#   - modules with components: under the module subdir (e.g lib/libX11-1.4.0)
#   - modules without components: under cwd (e.g xserver-1.14.0)
# The tarballs are expected to be under one of the locations described above
# The location of the tarball does not dictate where it is extracted
# arguments:
#   $1 - module
#   $2 - component
# returns:
#   0 - good (either no tarballs or successful extract)
#   1 - bad
checkfortars() {
    module=$1
    component=$2

    # The package stem is the part of the tar file name that identifies
    # the git module archived source. Ex: xclock, pixman, libX11
    # For modules without components, the module name is used by default.
    pkg_stem=${component:-$module}

    # Handle special cases where the module or component directory
    # does not match the package name and/or the package root dir
    case $module in
        "data")
            case $component in
                "cursors") pkg_stem="xcursor-themes" ;;
                "bitmaps") pkg_stem="xbitmaps" ;;
            esac
            ;;
        "font")
            if [ X"$component" != X"encodings" ]; then
                pkg_stem="font-$component"
            fi
            ;;
        "lib")
            case $component in
                "libXRes") pkg_stem="libXres" ;;
                "libxtrans") pkg_stem="xtrans" ;;
            esac
            ;;
        "proto")
            case $component in
                "x11proto") pkg_stem="xproto" ;;
            esac
            ;;
        "util")
            case $component in
                "cf") pkg_stem="xorg-cf-files" ;;
                "macros") pkg_stem="util-macros" ;;
            esac
            ;;
        "xcb")
            case $component in
                "proto")
                    pkg_stem="xcb-proto"
                    ;;
                "pthread-stubs")
                    pkg_stem="libpthread-stubs"
                    ;;
                "libxcb")
                    pkg_stem="libxcb"
                    ;;
                util*)
                    pkg_stem="xcb-$component"
                    ;;
            esac
            ;;
        "mesa")
            case $component in
                "drm")
                    pkg_stem="libdrm"
                    ;;
                "mesa")
                    pkg_stem="MesaLib"
                    ;;
            esac
            ;;
        "xserver")
            pkg_stem="xorg-server"
            ;;
    esac

    # Search for tarballs in both the module and the src top directory
    for ii in $module .; do
        for jj in bz2 gz xz; do

	    # Select from the list the last tarball with a specific pkg_stem
            pkg_tarfile=`ls -1rt $ii/$pkg_stem-[0-9]*.tar.$jj 2> /dev/null | tail -n 1`

	    # Extract the tarball under the module directory
	    # For modules without components, extract in top level dir
            if [ X"$pkg_tarfile" != X ]; then

		# Get the package version and archived toplevel directory
		pkg_version=`echo $pkg_tarfile | sed 's,.*'$pkg_stem'-\(.*\)\.tar\.'$jj',\1,'`
		pkg_root_dir="$pkg_stem-$pkg_version"
		pkg_root_dir=`echo $pkg_root_dir | sed 's,MesaLib,Mesa,'`

		# Find where to extract the tar file
		old_srcdir=$SRCDIR
		if [ X"$component" = X ]; then
		    # For modules with no components (i.e xserver)
		    pkg_extract_dir="."
		    SRCDIR=$pkg_root_dir
		else
		    # For modules with components (i.e xcb/proto or lib/libXi)
		    pkg_extract_dir=$module
		    SRCDIR=$module/$pkg_root_dir
		fi

                if [ ! -d $SRCDIR ]; then
		    mkdir -p $module
		    case $jj in
			"bz2")
			    pkg_tar_opts=xjf
			    ;;
			"gz")
			    pkg_tar_opts=xzf
			    ;;
			"xz")
			    pkg_tar_opts=xJf
			    ;;
		    esac
                    tar $pkg_tar_opts $pkg_tarfile -C $pkg_extract_dir
		    if [ $? -ne 0 ]; then
			SRCDIR=${old_srcdir}
			echo "Unable to extract $pkg_tarfile for $module module"
			failed tar $module $component
			return 1
		    fi
                fi
                return 0
            fi
        done
    done

    return 0
}

# perform a clone of a git repository
# this function provides the mapping between module/component names
# and their location in the fd.o repository
# arguments:
#   $1 - module
#   $2 - component (optional)
# returns:
#   0 - good
#   1 - bad
clone() {
    module=$1
    component=$2
    # preconds
    if [ X"$module" = X ]; then
	echo "clone() required first argument is missing"
	return 1
    fi

    case $module in
    "pixman")
        BASEDIR=""
        ;;
    "xcb")
        BASEDIR=""
        ;;
    "mesa")
        BASEDIR=""
        ;;
    "xkeyboard-config")
        BASEDIR=""
        ;;
    "libevdev")
        BASEDIR=""
        ;;
    "libinput")
	BASEDIR="wayland/"
	;;
    *)
        BASEDIR="xorg/"
        ;;
    esac

    DIR="$module${component:+/}$component"
    GITROOT=${GITROOT:="git://anongit.freedesktop.org/git"}

    if [ ! -d "$DIR" ]; then
        git clone $GITCLONEOPTS "$GITROOT/$BASEDIR$DIR" "$DIR"
        if [ $? -ne 0 ]; then
            echo "Failed to clone $module${component:+/}$component. Ignoring."
            clonefailed_components="$clonefailed_components $module${component:+/}$component"
            return 1
        fi
	old_pwd=`pwd`
	cd $DIR
	if [ $? -ne 0 ]; then
            echo "Failed to cd to $module${component:+/}$component. Ignoring."
            clonefailed_components="$clonefailed_components $module${component:+/}$component"
            return 1
	return 1
	fi
	git submodule init
        if [ $? -ne 0 ]; then
            echo "Failed to initialize $module${component:+/}$component submodule. Ignoring."
            clonefailed_components="$clonefailed_components $module${component:+/}$component"
            return 1
        fi
	git submodule update
        if [ $? -ne 0 ]; then
            echo "Failed to update $module${component:+/}$component submodule. Ignoring."
            clonefailed_components="$clonefailed_components $module${component:+/}$component"
            return 1
        fi
	cd ${old_pwd}
    else
        echo "git cannot clone into an existing directory $module${component:+/}$component"
	return 1
    fi

    return 0
}

# perform processing of each module/component
# arguments:
#   $1 - module
#   $2 - component
#   $3 - configure options
# returns:
#   0 - good
#   1 - bad
process() {
    module=$1
    component=$2
    confopts="$3"
    # preconds
    if [ X"$module" = X ]; then
	echo "process() required first argument is missing"
	return 1
    fi

    module_title $module "$component" "$confopts"

    local use_autogen=0
    local use_configure=0
    local use_meson=0

    SRCDIR=""
    CONFCMD=""
    if [ -f $module${component:+/}$component/autogen.sh ]; then
	SRCDIR="$module${component:+/}$component"
	use_autogen=1
    elif [ -f $module${component:+/}$component/meson.build ]; then
	SRCDIR="$module${component:+/}$component"
	use_meson=1
    elif [ X"$CLONE" != X ]; then
        clone $module $component
        if [ $? -eq 0 ]; then
	    SRCDIR="$module${component:+/}$component"
	    if [ -f $module${component:+/}$component/autogen.sh ]; then
		use_autogen=1
	    elif [ -f $module${component:+/}$component/meson.build ]; then
		use_meson=1
	    else
		echo "Cannot find autogen.sh or meson.build"
		return 1
	    fi
        fi
    else
        checkfortars $module $component
        if [ $? -eq 0 ]; then
	    if [ X"$SRCDIR" = X ]; then
	        echo "$module${component:+/}$component does not exist, skipping."
	        nonexistent_components="$nonexistent_components $module${component:+/}$component"
	        return 0
	    fi
	    use_configure=1
        else
	    return 1
	fi
    fi

    if [ $use_autogen != 0 ]; then
	CONFCMD="${DIR_CONFIG}/autogen.sh"
    elif [ $use_configure != 0 ]; then
	CONFCMD="${DIR_CONFIG}/configure"
    elif [ $use_meson != 0 ]; then
	CONFCMD="meson"
	confopts="$confopts builddir"
    fi

    old_pwd=`pwd`
    cd $SRCDIR
    if [ $? -ne 0 ]; then
	failed cd1 $module $component
	return 1
    fi

    if [ X"$GITCMD" != X ]; then
	$GITCMD
	rtn=$?
	cd $old_pwd

	if [ $rtn -ne 0 ]; then
	    failed "$GITCMD" $module $component
	    return 1
	fi
	return 0
    fi

    if [ X"$PULL" != X ]; then
	git pull --rebase
	if [ $? -ne 0 ]; then
	    failed "git pull" $module $component
	    cd $old_pwd
	    return 1
	fi
	# The parent module knows which commit the submodule should be at
	git submodule update
        if [ $? -ne 0 ]; then
	    failed "git submodule update" $module $component
            return 1
        fi
    fi

    # Build outside source directory
    if [ X"$DIR_ARCH" != X ] ; then
	mkdir -p "$DIR_ARCH"
	if [ $? -ne 0 ]; then
	    failed mkdir $module $component
	    cd $old_pwd
	    return 1
	fi
	cd "$DIR_ARCH"
	if [ $? -ne 0 ]; then
	    failed cd2 $module $component
	    cd ${old_pwd}
	    return 1
	fi
    fi

    # If the builddir already exists, just run ninja, not meson
    if [ $use_meson != 0 ] && [ -e ${DIR_CONFIG}/builddir ]; then
	:
    elif [ X"$NOAUTOGEN" = X ]; then
	${CONFCMD} \
	    ${PREFIX_USER:+--prefix="$PREFIX"} \
	    ${EPREFIX_USER:+--exec-prefix="$EPREFIX"} \
	    ${BINDIR_USER:+--bindir="$BINDIR"} \
	    ${DATAROOTDIR_USER:+--datarootdir="$DATAROOTDIR"} \
	    ${DATADIR_USER:+--datadir="$DATADIR"} \
	    ${LIBDIR_USER:+--libdir="$LIBDIR"} \
	    ${LOCALSTATEDIR_USER:+--localstatedir="$LOCALSTATEDIR"} \
	    ${QUIET:+--quiet} \
	    ${CONFFLAGS} $confopts
	if [ $? -ne 0 ]; then
	    failed ${CONFCMD} $module $component
	    cd $old_pwd
	    return 1
	fi
    else
	echo "build.sh: Skipping autogen/configure"
    fi

    # A custom 'make' target list was supplied through --cmd option
    # This does not work for ninja atm
    if [ X"$MAKECMD" != X ]; then
	${MAKE} $MAKEFLAGS $MAKECMD
	rtn=$?
	cd $old_pwd

	if [ $rtn -ne 0 ]; then
	    failed "$MAKE $MAKEFLAGS $MAKECMD" $module $component
	    return 1
	fi
	return 0
    fi

    if [ X"$NOMAKE" != X ]; then
	echo "build.sh: Skipping make targets"
	cd $old_pwd
	return 0
    fi


    if [ $use_autogen != 0 ] || [ $use_configure != 0 ]; then
	BUILDCMD="${MAKE} $MAKEFLAGS"
	BUILDCMD_VERBOSE="${BUILDCMD} V=1"
	BUILDCMD_CHECK="${BUILDCMD} check"
	BUILDCMD_CLEAN="${BUILDCMD} clean"
	BUILDCMD_DIST="${BUILDCMD} dist"
	BUILDCMD_DISTCHECK="${BUILDCMD} distcheck"
	BUILDCMD_INSTALL="${BUILDCMD} install"
    else
	BUILDCMD="ninja -C builddir"
	BUILDCMD_VERBOSE="${BUILDCMD_VERBOSE} -v"
	BUILDCMD_CHECK="${BUILDCMD} test"
	BUILDCMD_CLEAN="${BUILDCMD} clean"
	BUILDCMD_DIST="${BUILDCMD} dist"
	BUILDCMD_DISTCHECK="${BUILDCMD} distcheck"
	BUILDCMD_INSTALL="${BUILDCMD} install"
    fi


    $BUILDCMD
    if [ $? -ne 0 ]; then
	# Rerun with Automake silent rules disabled to see failing gcc statement
	if [ X"$RETRY_VERBOSE" != X ]; then
	    echo ""
	    echo "build.sh: Rebuilding $component with Automake silent rules disabled"
	    $BUILDCMD_VERBOSE
	fi
	failed "$BUILDCMD" $module $component
	cd $old_pwd
	return 1
    fi

    if [ X"$CHECK" != X ]; then
	$BUILDCMD_CHECK
	if [ $? -ne 0 ]; then
	    failed "$BUILDCMD_CHECK" $module $component
	    cd $old_pwd
	    return 1
	fi
    fi

    if [ X"$CLEAN" != X ]; then
	$BUILDCMD_CLEAN
	if [ $? -ne 0 ]; then
	    failed "$BUILDCMD_CLEAN" $module $component
	    cd $old_pwd
	    return 1
	fi
    fi

    if [ X"$DIST" != X ]; then
	$BUILDCMD_DIST
	if [ $? -ne 0 ]; then
	    failed "$BUILDCMD_DIST" $module $component
	    cd $old_pwd
	    return 1
	fi
    fi

    if [ X"$DISTCHECK" != X ]; then
	$BUILDCMD_DISTCHECK
	if [ $? -ne 0 ]; then
	    failed "$BUILDCMD_DISTCHECK" $module $component
	    cd $old_pwd
	    return 1
	fi
    fi

    $SUDO env LD_LIBRARY_PATH=$LD_LIBRARY_PATH $BUILDCMD_INSTALL
    if [ $? -ne 0 ]; then
	failed "$SUDO env LD_LIBRARY_PATH=$LD_LIBRARY_PATH $BUILDCMD_INSTALL" $module $component
	cd $old_pwd
	return 1
    fi

    cd ${old_pwd}

    return 0
}

# process each module/component and handle:
# LISTONLY, RESUME, NOQUIT, and BUILD_ONE
# arguments:
#   $1 - module
#   $2 - component
#   $3 - configure options
# returns:
#   0 - good
#   1 - bad
build() {
    module=$1
    component=$2
    confopts="$3"
    if [ X"$LISTONLY" != X ]; then
	echo "$module${component:+/}$component"
	return 0
    fi

    if [ X"$RESUME" != X ]; then
	if [ X"$RESUME" = X"$module${component:+/}$component" ]; then
	    unset RESUME
	    # Resume build at this module
	else
	    echo "Skipping $module${component:+/}$component..."
	    return 0
	fi
    fi

    process $module "$component" "$confopts"
    process_rtn=$?
    if [ X"$BUILT_MODULES_FILE" != X ]; then
	if [ $process_rtn -ne 0 ]; then
	    echo "FAIL: $module${component:+/}$component" >> $BUILT_MODULES_FILE
	else
	    echo "PASS: $module${component:+/}$component" >> $BUILT_MODULES_FILE
	fi
    fi

    if [ $process_rtn -ne 0 ]; then
	echo "build.sh: error processing:  \"$module${component:+/}$component\""
	if [ X"$NOQUIT" = X ]; then
	    exit 1
	fi
	return $process_rtn
    fi

    if [ X"$BUILD_ONE" != X ]; then
	echo "Single-component build complete"
	exit 0
    fi
}


# just process the sub-projects supplied in the given file ($MODFILE)
# in the order in which they are found in the list
# (prerequisites and ordering are the responsibility of the user)
# globals used:
#   $MODFILE - readable file containing list of modules to process
#              and their optional configuration options
# arguments:
#   (none)
# returns:
#   0 - good
#   1 - bad
process_module_file() {
    # preconds
    if [ X"$MODFILE" = X ]; then
	echo "internal process_module_file() error, \$MODFILE is empty"
	return 1
    fi
    if [ ! -r "$MODFILE" ]; then
	echo "module file '$MODFILE' is not readable or does not exist"
	return 1
    fi

    # read from input file, skipping blank and comment lines
    while read line; do
	# skip blank lines
	if [ X"$line" = X ]; then
	    continue
	fi

	# skip comment lines
	echo "$line" | grep "^#" > /dev/null
	if [ $? -eq 0 ]; then
	    continue
	fi

	# parse each line to extract module, component and options name
	field1=`echo $line | cut -d' ' -f1`
	module=`echo $field1 | cut -d'/' -f1`
	component=`echo $field1 | cut -d'/' -s -f2`
	confopts=`echo $line | cut -d' ' -s -f2-`

	build $module "$component" "$confopts"

    done <"$MODFILE"

    return 0
}

usage() {
    basename="`expr "//$0" : '.*/\([^/]*\)'`"
    echo "Usage: $basename [options] [prefix]"
    echo "Options:"
    echo "  -a          Do NOT run auto config tools (autogen.sh, configure)"
    echo "  -b          Use .build.unknown build directory"
    echo "  -c          Run make clean in addition to \"all install\""
    echo "  -D          Run make dist in addition to \"all install\""
    echo "  -d          Run make distcheck in addition \"all install\""
    echo "  -g          Compile and link with debug information"
    echo "  -h, --help  Display this help and exit successfully"
    echo "  -m          Do NOT run any of the make targets"
    echo "  -n          Do not quit after error; just print error message"
    echo "  -o module/component"
    echo "              Build just this module/component"
    echo "  -p          Update source code before building (git pull --rebase)"
    echo "  -s sudo     The command name providing superuser privilege"
    echo "  --autoresume resumefile"
    echo "              Append module being built to, and autoresume from, <file>"
    echo "  --check     Run make check in addition \"all install\""
    echo "  --clone     Clone non-existing repositories (uses \$GITROOT if set)"
    echo "  --cmd command"
    echo "              Execute arbitrary git, gmake, or make command"
    echo "  --confflags options"
    echo "              Pass options to autogen.sh/configure of all modules"
    echo "  --modfile modulefile"
    echo "              Only process the module/components specified in modulefile"
    echo "              Any text after, and on the same line as, the module/component"
    echo "              is assumed to be configuration options for the configuration"
    echo "              of each module/component specifically"
    echo "  --retry-v1  Remake 'all' on failure with Automake silent rules disabled"
    echo ""
    echo "Usage: $basename -L"
    echo "  -L          Just list modules to build"
    echo ""
    envoptions
}

# Ensure the named variable value contains a full path name
# arguments:
#   $1 - the variable value (the path to examine)
#   $2 - the name of the variable
# returns:
#   returns nothing or exit on error with message
check_full_path () {
    path=$1
    varname=$2
    if [ X"`expr $path : "\(.\)"`" != X/ ]; then
	echo "The path \"$path\" supplied by \"$varname\" must be a full path name"
	echo ""
	usage
	exit 1
    fi
}

# Ensure the named variable value contains a writable directory
# arguments:
#   $1 - the variable value (the path to examine)
#   $2 - the name of the variable
# returns:
#   returns nothing or exit on error with message
check_writable_dir () {
    path=$1
    varname=$2
    if [ X"$SUDO" = X ]; then
	if [ ! -d "$path" ] || [ ! -w "$path" ]; then
	    echo "The path \"$path\" supplied by \"$varname\" must be a writable directory"
	    echo ""
	    usage
	    exit 1
	fi
    fi
}

# perform sanity checks on cmdline args which require arguments
# arguments:
#   $1 - the option being examined
#   $2 - the argument to the option
# returns:
#   if it returns, everything is good
#   otherwise it exit's
required_arg() {
    option=$1
    arg=$2
    # preconds
    if [ X"$option" = X ]; then
	echo "internal required_arg() error, missing first argument"
	exit 1
    fi

    # check for an argument
    if [ X"$arg" = X ]; then
	echo "the '$option' option is missing its required argument"
	echo ""
	usage
	exit 1
    fi

    # does the argument look like an option?
    echo $arg | grep "^-" > /dev/null
    if [ $? -eq 0 ]; then
	echo "the argument '$arg' of option '$option' looks like an option itself"
	echo ""
	usage
	exit 1
    fi
}

#==============================================================================
#				Build All Modules
# Globals:
#   HOST_OS HOST_CPU
# Arguments:
#   None
# Returns:
#   None
#==============================================================================
build_all_modules() {

    build util macros
    build font util
    build doc xorg-sgml-doctools
    build doc xorg-docs
    build proto xorgproto
    build xcb proto
    build lib libxtrans
    build lib libXau
    build lib libXdmcp
    build xcb pthread-stubs
    build xcb libxcb
    build xcb util
    build xcb util-image
    build xcb util-keysyms
    build xcb util-renderutil
    build xcb util-wm
    build lib libX11
    build lib libXext
    case $HOST_OS in
        Darwin)  build lib libAppleWM;;
        CYGWIN*) build lib libWindowsWM;;
    esac
    build lib libdmx
    build lib libfontenc
    build lib libFS
    build lib libICE
    build lib libSM
    build lib libXt
    build lib libXmu
    build lib libXpm
    build lib libXaw
    build lib libXaw3d
    build lib libXfixes
    build lib libXcomposite
    build lib libXrender
    build lib libXdamage
    build lib libXcursor
    build lib libXfont
    build lib libXft
    build lib libXi
    build lib libXinerama
    build lib libxkbfile
    build lib libXrandr
    build lib libXRes
    build lib libXScrnSaver
    case $HOST_OS in
	Linux)
            build lib libxshmfence
	    ;;
    esac
    build lib libXtst
    build lib libXv
    build lib libXvMC
    build lib libXxf86dga
    build lib libXxf86vm
    build lib libpciaccess
    build pixman ""
    build mesa drm
    build mesa mesa
    build data bitmaps
    build app appres
    build app bdftopcf
    build app beforelight
    build app bitmap
    build app editres
    build app fonttosfnt
    build app fslsfonts
    build app fstobdf
    build app iceauth
    build app ico
    build app listres
    build app luit
    build app mkcomposecache
    build app mkfontscale
    build app oclock
    build app rgb
    build app rendercheck
    build app rstart
    build app scripts
    build app sessreg
    build app setxkbmap
    build app showfont
    build app smproxy
    build app twm
    build app viewres
    build app x11perf
    build app xauth
    build app xbacklight
    build app xbiff
    build app xcalc
    build app xclipboard
    build app xclock
    build app xcmsdb
    build app xconsole
    build app xcursorgen
    build app xdbedizzy
    build app xditview
    build app xdm
    build app xdpyinfo
    build app xdriinfo
    build app xedit
    build app xev
    build app xeyes
    build app xf86dga
    build app xfd
    build app xfontsel
    build app xfs
    build app xfsinfo
    build app xgamma
    build app xgc
    build app xhost
    build app xinit
    build app xinput
    build app xkbcomp
    build app xkbevd
    build app xkbprint
    build app xkbutils
    build app xkill
    build app xload
    build app xlogo
    build app xlsatoms
    build app xlsclients
    build app xlsfonts
    build app xmag
    build app xman
    build app xmessage
    build app xmh
    build app xmodmap
    build app xmore
    build app xpr
    build app xprop
    build app xrandr
    build app xrdb
    build app xrefresh
    build app xscope
    build app xset
    build app xsetmode
    build app xsetroot
    build app xsm
    build app xstdcmap
    build app xvidtune
    build app xvinfo
    build app xwd
    build app xwininfo
    build app xwud
    build xserver ""
    case $HOST_OS in
	Linux)
	    build libevdev ""
	    build libinput ""
	    ;;
    esac
    case $HOST_OS in
	Linux)
	    build driver xf86-input-evdev
	    build driver xf86-input-joystick
	    build driver xf86-input-libinput
	    ;;
	FreeBSD | NetBSD | OpenBSD | Dragonfly | GNU/kFreeBSD)
	    build driver xf86-input-joystick
	    ;;
    esac
    case $HOST_CPU in
	i*86 | amd64 | x86_64 | i86pc)
	    build driver xf86-input-vmmouse
	    ;;
    esac
    case $HOST_OS in
        Darwin)
	    ;;
	*)
	    build driver xf86-input-keyboard
	    build driver xf86-input-mouse
	    build driver xf86-input-synaptics
	    build driver xf86-input-void
	    case $HOST_OS in
		FreeBSD)
		    case $HOST_CPU in
			sparc64)
			    build driver xf86-video-sunffb
			    ;;
		    esac
		    ;;
		NetBSD | OpenBSD)
		    build driver xf86-video-wsfb
		    build driver xf86-video-sunffb
		    ;;
		Linux)
		    build driver xf86-video-sisusb
		    build driver xf86-video-sunffb
		    build driver xf86-video-v4l
		    build driver xf86-video-xgixp
		    case $HOST_CPU in
			i*86)
	                    # AMD Geode CPU. Driver contains 32 bit assembler code
			    build driver xf86-video-geode
			    ;;
		    esac
		    ;;
	    esac
	    case $HOST_CPU in
		sparc | sparc64)
		    build driver xf86-video-suncg14
		    build driver xf86-video-suncg3
		    build driver xf86-video-suncg6
		    build driver xf86-video-sunleo
		    build driver xf86-video-suntcx
		    ;;
		i*86 | amd64 | x86_64 | i86pc)
	            build driver xf86-video-i740
	            build driver xf86-video-intel
		    ;;
	    esac
	    build driver xf86-video-amdgpu
	    build driver xf86-video-apm
	    build driver xf86-video-ark
	    build driver xf86-video-ast
	    build driver xf86-video-ati
	    build driver xf86-video-chips
	    build driver xf86-video-cirrus
	    build driver xf86-video-dummy
	    build driver xf86-video-fbdev
	    build driver xf86-video-glint
	    build driver xf86-video-i128
	    build driver xf86-video-mach64
	    build driver xf86-video-mga
	    build driver xf86-video-neomagic
	    build driver xf86-video-nested
	    build driver xf86-video-nv
	    build driver xf86-video-rendition
	    build driver xf86-video-r128
	    build driver xf86-video-s3
	    build driver xf86-video-s3virge
	    build driver xf86-video-savage
	    build driver xf86-video-siliconmotion
	    build driver xf86-video-sis
	    build driver xf86-video-tdfx
	    build driver xf86-video-tga
	    build driver xf86-video-trident
	    build driver xf86-video-tseng
	    build driver xf86-video-vesa
	    build driver xf86-video-vmware
	    build driver xf86-video-voodoo
	    ;;
    esac
    build data cursors
    build font encodings
    build font adobe-100dpi
    build font adobe-75dpi
    build font adobe-utopia-100dpi
    build font adobe-utopia-75dpi
    build font adobe-utopia-type1
    build font arabic-misc
    build font bh-100dpi
    build font bh-75dpi
    build font bh-lucidatypewriter-100dpi
    build font bh-lucidatypewriter-75dpi
    build font bh-ttf
    build font bh-type1
    build font bitstream-100dpi
    build font bitstream-75dpi
    build font bitstream-type1
    build font cronyx-cyrillic
    build font cursor-misc
    build font daewoo-misc
    build font dec-misc
    build font ibm-type1
    build font isas-misc
    build font jis-misc
    build font micro-misc
    build font misc-cyrillic
    build font misc-ethiopic
    build font misc-meltho
    build font misc-misc
    build font mutt-misc
    build font schumacher-misc
    build font screen-cyrillic
    build font sony-misc
    build font sun-misc
    build font winitzki-cyrillic
    build font xfree86-type1
    build font alias
    build util cf
    build util imake
    build util gccmakedep
    build util lndir
    build util makedepend
    build xkeyboard-config ""
    return 0
}


#------------------------------------------------------------------------------
#			Script main line
#------------------------------------------------------------------------------

# Initialize variables controlling end of run reports
failed_components=""
nonexistent_components=""
clonefailed_components=""

# Set variables supporting multiple binaries for a single source tree
HAVE_ARCH="`uname -i`"
DIR_ARCH=""
DIR_CONFIG="."

# Set variables for conditionally building some components
HOST_OS=`uname -s`
export HOST_OS
HOST_CPU=`uname -m`
export HOST_CPU

# Process command line args
while [ $# != 0 ]
do
    case $1 in
    -a)
	NOAUTOGEN=1
	;;
    -b)
	DIR_ARCH=".build.$HAVE_ARCH"
	DIR_CONFIG=".."
	;;
    -c)
	CLEAN=1
	;;
    -D)
	DIST=1
	;;
    -d)
	DISTCHECK=1
	;;
    -g)
	CFLAGS="${CFLAGS} -g3 -O0"
	export CFLAGS
	;;
    -h|--help)
	usage
	exit 0
	;;
    -L)
	LISTONLY=1
	;;
    -m)
	NOMAKE=1
	;;
    -n)
	NOQUIT=1
	;;
    -o)
	if [ -n "$BUILT_MODULES_FILE" ]; then
	    echo "The '-o' and '--autoresume' options are mutually exclusive."
	    usage
	    exit 1
	fi
	required_arg $1 $2
	shift
	RESUME=`echo $1 | sed "s,/$,,"`
	BUILD_ONE=1
	;;
    -p)
	PULL=1
	;;
    -s)
	required_arg $1 $2
	shift
	SUDO=$1
	;;
    --autoresume)
	if [ -n "$BUILD_ONE" ]; then
	    echo "The '-o' and '--autoresume' options are mutually exclusive."
	    usage
	    exit 1
	fi
	required_arg $1 $2
	shift
	BUILT_MODULES_FILE=$1
	;;
    --check)
	CHECK=1
	;;
    --clone)
	CLONE=1
	;;
    --cmd)
	required_arg $1 $2
	shift
	cmd1=`echo $1 | cut -d' ' -f1`
	cmd2=`echo $1 | cut -d' ' -f2`

	# verify the command exists
	which $cmd1 > /dev/null 2>&1
	if [ $? -ne 0 ]; then
	    echo "The specified command '$cmd1' does not appear to exist"
	    echo ""
	    usage
	    exit 1
	fi

	case X"$cmd1" in
	    X"git")
		GITCMD=$1
		;;
	    X"make" | X"gmake")
		MAKECMD=$cmd2
		;;
	    *)
		echo "The script can only process 'make', 'gmake', or 'git' commands"
		echo "It can't process '$cmd1' commands"
		echo ""
		usage
		exit 1
		;;
	esac
	;;
    --confflags)
	shift
	CONFFLAGS=$1
	;;
    --modfile)
	required_arg $1 $2
	shift
	if [ ! -r "$1" ]; then
	    echo "can't find/read file '$1'"
	    exit 1
	fi
	MODFILE=$1
	;;
    --retry-v1)
	RETRY_VERBOSE=1
	;;
    *)
	if [ X"$too_many" = Xyes ]; then
	    echo "unrecognized and/or too many command-line arguments"
	    echo "  PREFIX:               $PREFIX"
	    echo "  Extra arguments:      $1"
	    echo ""
	    usage
	    exit 1
	fi

	# check that 'prefix' doesn't look like an option
	echo $1 | grep "^-" > /dev/null
	if [ $? -eq 0 ]; then
	    echo "'prefix' appears to be an option"
	    echo ""
	    usage
	    exit 1
	fi

	PREFIX=$1
	too_many=yes
	;;
    esac

    shift
done

# All user input has been obtained, set-up the user shell variables
if [ X"$LISTONLY" = X ]; then
    setup_buildenv
    echo "Building to run $HOST_OS / $HOST_CPU ($HOST)"
    date
fi

# if   there is a BUILT_MODULES_FILE
# then start off by checking for and trying to build any modules which failed
#      and aren't the last line
if [ X"$BUILT_MODULES_FILE" != X -a -r "$BUILT_MODULES_FILE" ]; then
    built_lines=`cat $BUILT_MODULES_FILE | wc -l | sed 's:^ *::'`
    built_lines_m1=`expr $built_lines - 1`
    orig_BUILT_MODULES_FILE=$BUILT_MODULES_FILE
    unset BUILT_MODULES_FILE
    curline=1
    while read line; do
	built_status=`echo $line | cut -c-6`
	if [ X"$built_status" = X"FAIL: " ]; then
	    line=`echo $line | cut -c7-`
	    field1=`echo $line | cut -d' ' -f1`
	    module=`echo $field1 | cut -d'/' -f1`
	    component=`echo $field1 | cut -d'/' -s -f2`
	    confopts=`echo $line | cut -d' ' -s -f2-`

	    build_ret=""

	    # quick check for the module in $MODFILE (if present)
	    if [ X"$MODFILE" = X ]; then
		build $module "$component" "$confopts"
		if [ $? -eq 0 ]; then
		    build_ret="PASS"
		fi
	    else
		cat $MODFILE | grep "$module${component:+/}$component" > /dev/null
		if [ $? -eq 0 ]; then
		    build $module "$component" "$confopts"
		    if [ $? -eq 0 ]; then
			build_ret="PASS"
		    fi
		fi
	    fi

	    if [ X"$build_ret" = X"PASS" ]; then
		built_temp=`mktemp`
		if [ $? -ne 0 ]; then
		    echo "can't create tmp file, $orig_BUILT_MODULES_FILE not modified"
		else
		    head -n `expr $curline - 1` $orig_BUILT_MODULES_FILE > $built_temp
		    echo "PASS: $module${component:+/}$component" >> $built_temp
		    tail -n `expr $built_lines - $curline` $orig_BUILT_MODULES_FILE >> $built_temp
		    mv $built_temp $orig_BUILT_MODULES_FILE
		fi
	    fi
	fi
	if [ $curline -eq $built_lines_m1 ]; then
	    break
	fi
	curline=`expr $curline + 1`
    done <"$orig_BUILT_MODULES_FILE"

    BUILT_MODULES_FILE=$orig_BUILT_MODULES_FILE
    RESUME=`tail -n 1 $BUILT_MODULES_FILE | cut -c7-`

    # remove last line of $BUILT_MODULES_FILE
    # to avoid a duplicate entry
    built_temp=`mktemp`
    if [ $? -ne 0 ]; then
	echo "can't create tmp file, last built item will be duplicated"
    else
	head -n $built_lines_m1 $BUILT_MODULES_FILE > $built_temp
	mv $built_temp $BUILT_MODULES_FILE
    fi
fi

if [ X"$MODFILE" = X ]; then
    build_all_modules
else
    process_module_file
fi

if [ X"$LISTONLY" != X ]; then
    exit 0
fi

# Print the end date/time to compare with the start date/time
date

# Report about components that failed for one reason or another
if [ X"$nonexistent_components" != X ]; then
    echo ""
    echo "***** Skipped components (not available) *****"
	echo "Could neither find a git repository (at the <module/component> paths)"
	echo "or a tarball (at the <module/> paths or ./) for:"
	echo "    <module/component>"
    for mod in $nonexistent_components; do
	echo "    $mod"
    done
    echo "You may want to provide the --clone option to build.sh"
    echo "to automatically git-clone the missing components"
    echo ""
fi

if [ X"$failed_components" != X ]; then
    echo ""
    echo "***** Failed components *****"
    for mod in $failed_components; do
	echo "    $mod"
    done
    echo ""
fi

if [ X"$CLONE" != X ] && [ X"$clonefailed_components" != X ];  then
    echo ""
    echo "***** Components failed to clone *****"
    for mod in $clonefailed_components; do
	echo "    $mod"
    done
    echo ""
fi

