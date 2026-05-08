OPENVPN_VERSION ?= 2.6.20
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
	@MAJOR=$$(echo $(OPENVPN_VERSION) | cut -d. -f1); \
	MINOR=$$(echo $(OPENVPN_VERSION) | cut -d. -f2); \
	PATCHDIR="patches/$${MAJOR}.$${MINOR}.x"; \
	if [ ! -d "$$PATCHDIR" ]; then \
		echo "ERROR: No patches for $$MAJOR.$$MINOR.x"; \
		echo "Available: $$(ls -d patches/*/)"; \
		exit 1; \
	fi; \
	cd $(SOURCE_DIR); \
	for p in ../$$PATCHDIR/*.patch; do \
		echo "  Applying $$(basename $$p)..."; \
		patch -p1 < "$$p"; \
	done

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
