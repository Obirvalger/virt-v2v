# libguestfs
# Copyright (C) 2009-2019 Red Hat Inc.
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

include $(top_srcdir)/common-rules.mk

ACLOCAL_AMFLAGS = -I m4

SUBDIRS = common/mlstdutils

# Files and other test data used by the tests.  Must be before any
# tests run, except tests/qemu.
SUBDIRS += test-data

# Gnulib - must be built and tested before the program.
SUBDIRS += gnulib/lib
if ENABLE_GNULIB_TESTS
SUBDIRS += gnulib/tests
endif

SUBDIRS += common/qemuopts
SUBDIRS += common/utils
SUBDIRS += common/mlutils
SUBDIRS += common/mlaugeas
SUBDIRS += common/mlpcre
SUBDIRS += common/options
SUBDIRS += common/windows
SUBDIRS += common/mlgettext
SUBDIRS += common/mlxml
SUBDIRS += common/mltools
SUBDIRS += common/mlcustomize
SUBDIRS += common/mlv2v
SUBDIRS += common/mllibvirt
SUBDIRS += v2v
SUBDIRS += test-harness

SUBDIRS += tests

# bash-completion
SUBDIRS += bash

# Documentation
SUBDIRS += docs

# After all source files were used we can generate the translation strings
SUBDIRS += po

# po-docs must come after tools, inspector.
if HAVE_PO4A
SUBDIRS += po-docs
endif

# lib/guestfs-internal-all.h is a hack, remove it XXX
EXTRA_DIST = \
	.gitignore \
	bootstrap \
	autogen.sh \
	check-mli.sh \
	common/.gitignore \
	common/README \
	lib/guestfs-internal-all.h \
	m4/.gitignore \
	ocaml-link.sh \
	podcheck.pl \
	tmp/.gitignore \
	valgrind-suppressions \
	zanata.xml \
	zanata-pull.sh

# When doing 'make dist' update a few files automatically.
#
#  ChangeLog      - changelog (created from git)
#  po/POTFILES-ml - OCaml files, which need a special tool to translate

dist-hook: ChangeLog po/POTFILES-ml
	cp ChangeLog $(distdir)/ChangeLog

ChangeLog: configure.ac
	rm -f $@ $@-t
	git log --decorate=false > $@-t
	mv $@-t $@

po/POTFILES-ml: configure.ac
	rm -f $@ $@-t
	cd $(srcdir); \
	find common/ml* v2v -name '*.ml' | \
	grep -v '^v2v/config.ml$$' | \
	LC_ALL=C sort > $@-t
	mv $@-t $@

# NB. podwrapper is an internal tool, so the man page mustn't be installed.
# It should be noinst_MANS but that doesn't work.
noinst_DATA = podwrapper.1
podwrapper.1: podwrapper.pl
	$(PODWRAPPER) \
	  --section 1 \
	  --man $@-t \
	  --license GPLv2+ \
	  --warning safe \
	  $<
	mv $@-t $@

# Make clean.

CLEANFILES += \
	pod2htm?.tmp \
	tmp/disk* \
	tmp/run-* \
	tmp/valgrind-*.log

clean-local:
	-rm -rf tmp/libguestfs??????
	-rm -rf tmp/guestfs.*
	-rm -rf tmp/.guestfs-*
	-rm -rf tmp/null.*
	-find tmp -type s -delete
	-find . -name '*~' -delete

check-valgrind: build-test-guests
	@errors=0; \
	for f in `grep -l '^$@:' $(SUBDIRS:%=%/Makefile.am)`; do \
	  echo $(MAKE) -C `dirname $$f` $@; \
	  $(MAKE) -C `dirname $$f` $@ || (( errors++ )); \
	done; \
	exit $$(( $$errors ? 1 : 0 ))

check-slow: build-test-guests
	@errors=0; \
	for f in `grep -l '^$@:' $(SUBDIRS:%=%/Makefile.am)`; do \
	  echo $(MAKE) -C `dirname $$f` $@; \
	  $(MAKE) -C `dirname $$f` $@ || (( errors++ )); \
	done; \
	exit $$(( $$errors ? 1 : 0 ))

build-test-guests:
	$(MAKE) -C test-data/phony-guests check

# Some tests which run at the top level.

TESTS = check-mli.sh

# Commit everything in current directory to HEAD, and set commit
# message to current version (only for maintainer).

maintainer-commit:
	git commit -a -m "Version $(VERSION)."

# Tag HEAD with current version (only for maintainer).

maintainer-tag:
	git tag -a "v$(VERSION)" -m "Version $(VERSION) ($(BRANCH_TYPE))" -f

# Maintainer only: check no files are missing from EXTRA_DIST rules,
# and that all generated files have been included in the tarball.
# (Note you must have done 'make dist')

maintainer-check-extra-dist:
	zcat $(PACKAGE_NAME)-$(VERSION).tar.gz | tar tf - | sort | \
	  sed 's,^$(PACKAGE_NAME)-$(VERSION)/,,' > tmp/tarfiles
	( git ls-files ; \
	  cd common; git ls-files | sed 's,^,common/,' ) | \
	  grep -v '^common$$' | \
	  grep -v '^intltool-.*\.in' | \
	  grep -v '^\.gitmodules' | \
	  grep -v '^\.gnulib' | \
	  sort > tmp/gitfiles
	comm -13 tmp/tarfiles tmp/gitfiles > tmp/comm-out
	@echo Checking for differences between EXTRA_DIST and git ...
	cat tmp/comm-out
	[ ! -s tmp/comm-out ]
	rm tmp/tarfiles tmp/gitfiles tmp/comm-out
	@echo PASS: EXTRA_DIST tests