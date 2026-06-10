OPENVPN_VERSION = 2.7.4
SOURCE_DIR = openvpn-source
BINARY = openvpn-aws

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
	@echo "Applying patches..."
	cd $(SOURCE_DIR) && patch -p1 < "../0001-unprivileged.patch"
	cd $(SOURCE_DIR) && patch -p1 < "../aws.patch"
	cd $(SOURCE_DIR) && patch -p1 < "../patches/push-reply-prefix-fix.patch"

build: patch
	@echo "Building..."
	cd $(SOURCE_DIR) && autoreconf -fvi
	cd $(SOURCE_DIR) && ./configure --prefix=/usr --sbindir=/usr/bin
	$(MAKE) -C $(SOURCE_DIR) -j$(nproc)
	cp $(SOURCE_DIR)/src/openvpn/openvpn $(BINARY)
	strip $(BINARY)
	@echo "Built: $(BINARY)"

install: build
	cp $(BINARY) /usr/local/bin/openvpn-aws
	chmod +x /usr/local/bin/openvpn-aws
	@echo "Installed to /usr/local/bin/openvpn-aws"

clean:
	rm -rf $(SOURCE_DIR) $(BINARY) openvpn-*.tar.gz
