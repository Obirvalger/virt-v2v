#!/bin/bash -
# libguestfs virt-v2v test script
# Copyright (C) 2014 Red Hat Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Test -i ova option.

unset CDPATH
export LANG=C
set -e

if [ -n "$SKIP_TEST_V2V_I_OVA_SH" ]; then
    echo "$0: test skipped because environment variable is set"
    exit 77
fi

if [ "$(guestfish get-backend)" = "uml" ]; then
    echo "$0: test skipped because UML backend does not support network"
    exit 77
fi

# XXX Remove when we fix this.  See:
# https://www.redhat.com/archives/libguestfs/2017-February/msg00101.html
if [[ "$(guestfish get-backend)" =~ ^libvirt ]]; then
    echo "$0: test skipped because of bug with virt-v2v -i ova and libvirt"
    exit 77
fi

f=../test-data/phony-guests/windows.img
if ! test -f $f || ! test -s $f; then
    echo "$0: test skipped because phony Windows image was not created"
    exit 77
fi

export VIRT_TOOLS_DATA_DIR="$srcdir/../test-data/fake-virt-tools"
export VIRTIO_WIN="$srcdir/../test-data/fake-virtio-win"

. $srcdir/../test-data/test-utils.sh

d=test-v2v-i-ova.d
rm -rf $d
mkdir $d

vmdk=test-ova.vmdk
ovf=test-v2v-i-ova.ovf
mf=test-ova.mf
ova=test-ova.ova
raw=TestOva-sda

qemu-img convert $f -O vmdk $d/$vmdk
cp $ovf $d/$ovf
sha1=`do_sha1 $d/$ovf`
echo "SHA1($ovf)= $sha1" > $d/$mf
sha256=`do_sha256 $d/$vmdk`
echo "SHA256($vmdk)= $sha256" >> $d/$mf

pushd .
cd $d
tar -cf $ova $ovf $mf $vmdk
rm -rf $ovf $mf $vmdk
popd

$VG virt-v2v --debug-gc \
    -i ova $d/$ova \
    -o local -of raw -os $d

# Test the libvirt XML metadata and a disk was created.
test -f $d/$raw
test -f $d/TestOva.xml

# Normalize the XML output.
mv $d/TestOva.xml $d/TestOva.xml.old
sed \
    -e "s,source file='.*TestOva-sda',source file='TestOva-sda'," \
    -e "s,generated by.*--,generated by --," \
    < $d/TestOva.xml.old > $d/TestOva.xml

# Check the libvirt XML output.
diff -u test-v2v-i-ova.xml $d/TestOva.xml

rm -rf $d
