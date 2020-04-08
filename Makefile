# PREFIX is where we will ultimately be installed to
# (So we can tell bearwall where it is going to be running from)
PREFIX ?= /usr/local
# DESTDIR is where we are installing to
# (allows us to install in staging dir for packaging)
DESTDIR ?=

BINDIR ?= $(PREFIX)/sbin
SHARDIR ?=$(PREFIX)/share
ETCDIR ?= $(PREFIX)/etc
CACHEDIR ?= $(PREFIX)/var/cache

PKGNAME=bearwall2

BASEDIR ?= $(SHARDIR)/$(PKGNAME)
CONFDIR ?= $(ETCDIR)/$(PKGNAME)
MANDIR ?= $(SHARDIR)/man
DATADIR ?= $(CACHEDIR)/$(PKGNAME)

RULESET := $(wildcard ruleset.d/*)
CLASSES := $(wildcard classes.d/*)
INTERFACES := $(wildcard interfaces.d/*)
SUPPORT := $(wildcard support/*)

all: build-bearwall2

build-bearwall2:
	@sed -e s#@BASEDIR@#$(BASEDIR)#g -e s#@CONFDIR@#$(CONFDIR)#g -e s#@DATADIR@#$(DATADIR)#g \
		src/bearwall2.in \
		>src/$(PKGNAME)
	@sed -e s#@CONFDIR@#$(CONFDIR)#g \
		src/config.in \
		>src/$(PKGNAME).conf
	@sed -e s#@BASEDIR@#$(subst -,\\\\-,$(BASEDIR))#g \
		-e s#@CONFDIR@#$(subst -,\\\\-,$(CONFDIR))#g \
		-e s#@PKGNAME@#$(subst -,\\\\-,$(PKGNAME))#g \
		doc/bearwall2.md.in \
		>doc/$(PKGNAME).md
	pandoc -s -o doc/bearwall2.8 doc/bearwall2.md

clean:
	@rm -f src/$(PKGNAME) doc/$(PKGNAME).md doc/$(PKGNAME).8 src/$(PKGNAME).conf
	@rm -f $(PKGNAME)-*.tar.*

install-bin: all

	install -D --group=root --mode=755 --owner=root \
		src/$(PKGNAME) $(DESTDIR)$(BINDIR)/$(PKGNAME)

	install -d --group=root --mode=755 --owner=root \
		$(DESTDIR)$(BASEDIR)/ruleset.d
	for i in $(RULESET); \
		do install -D --group=root --mode=644 --owner=root \
		$$i $(DESTDIR)$(BASEDIR)/$$i; \
		done

	install -d --group=root --mode=755 --owner=root \
		$(DESTDIR)$(BASEDIR)/support
	for i in $(SUPPORT); \
		do install -D --group=root --mode=644 --owner=root \
		$$i $(DESTDIR)$(BASEDIR)/$$i; \
		done

install-data: all
	install -d --group=root --mode=755 --owner=root \
		$(DESTDIR)$(DATADIR)


install-conf: all

	install -D --group=root --mode=644 --owner=root \
		src/$(PKGNAME).conf $(DESTDIR)$(CONFDIR)/$(PKGNAME).conf

	install -d --group=root --mode=755 --owner=root \
		$(DESTDIR)$(CONFDIR)/classes.d
	for i in $(CLASSES); \
		do install -D --group=root --mode=644 --owner=root \
		$$i $(DESTDIR)$(CONFDIR)/$$i; \
		done

	install -d --group=root --mode=755 --owner=root \
		$(DESTDIR)$(CONFDIR)/interfaces.d
	for i in $(INTERFACES); \
		do install -D --group=root --mode=644 --owner=root \
		$$i $(DESTDIR)$(CONFDIR)/$$i; \
		done

	install -d --group=root --mode=755 --owner=root \
		$(DESTDIR)$(CONFDIR)/ruleset.d

install-doc: all

	install -d --group=root --mode=755 --owner=root \
		$(DESTDIR)$(MANDIR)/man8
	install --group=root --mode=644 --owner=root \
		doc/$(PKGNAME).8 $(DESTDIR)$(MANDIR)/man8
	install --group=root --mode=644 --owner=root \
		doc/$(PKGNAME).8 $(DESTDIR)$(MANDIR)/man8

install: install-bin install-conf install-doc install-data

.PHONY: clean all build-bearwall2 install install-bin install-conf install-doc

deb:
	@mk-build-deps -i -r -t 'apt-get -f -y --force-yes'
	@dpkg-buildpackage -b -us -uc -rfakeroot
