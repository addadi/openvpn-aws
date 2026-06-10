OPENVPN_VERSION = 2.7.4
SOURCE_DIR = openvpn-source
BINARY = openvpn-aws

# Select patch set by upstream version: 2.7.x+ vs 2.6.x
VERSION_MAJOR = $(word 1,$(subst ., ,$(OPENVPN_VERSION)))
VERSION_MINOR = $(word 2,$(subst ., ,$(OPENVPN_VERSION)))
IS_27_OR_NEWER = $(shell [ $(VERSION_MAJOR) -gt 2 ] || { [ $(VERSION_MAJOR) -eq 2 ] && [ $(VERSION_MINOR) -ge 7 ]; } && echo yes)
ifeq ($(IS_27_OR_NEWER),yes)
UNPRIV_PATCH = 0001-unprivileged-2.7.x.patch
AWS_PATCH = aws-2.7.x.patch
PREFIX_PATCH = patches/push-reply-prefix-fix-2.7.x.patch
else
UNPRIV_PATCH = 0001-unprivileged.patch
AWS_PATCH = aws.patch
PREFIX_PATCH = patches/push-reply-prefix-fix.patch
endif

.PHONY: all clean fetch patch build install

all: build

fetch:
	@echo "Fetching OpenVPN $(OPENVPN_VERSION) source..."
	curl -fL -o "openvpn-$(OPENVPN_VERSION).tar.gz" "https://github.com/OpenVPN/openvpn/archive/refs/tags/v$(OPENVPN_VERSION).tar.gz"
	@echo "Verifying upstream tarball checksum..."
	grep "  openvpn-$(OPENVPN_VERSION).tar.gz$$" upstream-sha256sums | sha256sum -c -
	tar xzf "openvpn-$(OPENVPN_VERSION).tar.gz"
	mv "openvpn-$(OPENVPN_VERSION)" $(SOURCE_DIR)

patch: fetch
	@echo "Applying patches for OpenVPN $(OPENVPN_VERSION)..."
	cd $(SOURCE_DIR) && patch -p1 < "../$(UNPRIV_PATCH)"
	cd $(SOURCE_DIR) && patch -p1 < "../$(AWS_PATCH)"
	cd $(SOURCE_DIR) && patch -p1 < "../$(PREFIX_PATCH)"

build: patch
	@echo "Building..."
	cd $(SOURCE_DIR) && autoreconf -fvi
	cd $(SOURCE_DIR) && ./configure --prefix=/usr --sbindir=/usr/bin
	$(MAKE) -C $(SOURCE_DIR) -j$(shell nproc)
	cp $(SOURCE_DIR)/src/openvpn/openvpn $(BINARY)
	strip $(BINARY)
	@echo "Built: $(BINARY)"

install: build
	cp $(BINARY) /usr/local/bin/openvpn-aws
	chmod +x /usr/local/bin/openvpn-aws
	@echo "Installed to /usr/local/bin/openvpn-aws"

clean:
	rm -rf $(SOURCE_DIR) $(BINARY) openvpn-*.tar.gz
