#!/bin/sh

module=
version=

usage()
{
    cat <<EOF
Usage: `basename $0` MODULESET SHA1SUM TARBALL

Updates the module associated to TARBALL in MODULESET.
EOF
}

# check input arguments
moduleset=$1
sha1sum=$2
tarball=$3
if [ -z "$moduleset" ] || [ -z "$sha1sum" ] || [ -z "$tarball" ]; then
    echo "error: Not enough arguments" >&2
    usage >&2
    exit 1
fi

# check that the moduleset exists and is writable
if [ ! -w "$moduleset" ]; then
    echo "error: moduleset \"$moduleset\" does not exist or is not writable" >&2
    exit 1
fi

# we only want the tarball name
tarball=`basename $tarball`

# pull the module and version from the tarball
module=${tarball%-*}
version=${tarball##*-}
version=${version%.tar*}

# sometimes the jhbuild id doesn't match the tarball name
module_id=$module
case "$module" in
    xorg-server)
        module_id=xserver
        ;;
    util-macros)
        module_id=macros
        ;;
    libXres)
        module_id=libXRes
        ;;
    xtrans)
        module_id=libxtrans
        ;;
    xbitmaps)
        module_id=bitmaps
        ;;
    MesaLib)
        module_id=libGL
        ;;
    xcursor-themes)
        module_id=cursors
        ;;
    libpthread-stubs)
        module_id=pthread-stubs
        ;;
    xproto)
        module_id=x11proto
        ;;
esac

# edit the moduleset
sed -i \
    "/id=\"$module_id\"/{
        # read the next line until we get />, which should be the end
        # of the branch tag
        :next
        N
        /\/>$/!b next

        # update the info
        s/$module-[^\"]*\"/$tarball\"/
        s/version=\"[^\"]*\"/version=\"$version\"/
        s/hash=\"[^\"]*\"/hash=\"sha1:$sha1sum\"/
    }" "$moduleset"
