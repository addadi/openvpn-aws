OPENVPN_VERSION = 2.6.12
SOURCE_DIR = openvpn-source
BINARY = openvpn-aws

.PHONY: all clean fetch patch build install

all: build

fetch:
	@echo "Fetching OpenVPN $(OPENVPN_VERSION) source..."
	curl -L "https://github.com/OpenVPN/openvpn/archive/refs/tags/v$(OPENVPN_VERSION).tar.gz" | tar xz
	mv "openvpn-$(OPENVPN_VERSION)" $(SOURCE_DIR)

patch: fetch
	@echo "Applying patches..."
	cd $(SOURCE_DIR) && patch -p1 < "../0001-unprivileged.patch"
	cd $(SOURCE_DIR) && patch -p1 < "../aws.patch"

build: patch
	@echo "Building..."
	cd $(SOURCE_DIR) && autoreconf -fvi
	cd $(SOURCE_DIR) && ./configure --prefix=/usr --sbindir=/usr/bin
	$(MAKE) -C $(SOURCE_DIR) -j$$(nproc)
	cp $(SOURCE_DIR)/src/openvpn/openvpn $(BINARY)
	strip $(BINARY)
	@echo "Built: $(BINARY)"

install: build
	cp $(BINARY) /usr/local/bin/openvpn-aws
	chmod +x /usr/local/bin/openvpn-aws
	@echo "Installed to /usr/local/bin/openvpn-aws"

clean:
	rm -rf $(SOURCE_DIR) $(BINARY)
