VERSION       := $(shell git describe --tags --always --dirty="-dev")
DATE          := $(shell date -u '+%Y-%m-%d-%H%M UTC')
VERSION_FLAGS := -ldflags='-X "main.Version=$(VERSION)" -X "main.BuildTime=$(DATE)"'

IMPORT_PATH   := github.com/cloudflare/cloudflared
PACKAGE_DIR   := $(CURDIR)/packaging
INSTALL_BINDIR := usr/local/bin

EQUINOX_FLAGS = --version="$(VERSION)" \
				 --platforms="$(EQUINOX_BUILD_PLATFORMS)" \
				 --app="$(EQUINOX_APP_ID)" \
				 --token="$(EQUINOX_TOKEN)" \
				 --channel="$(EQUINOX_CHANNEL)"

ifeq ($(EQUINOX_IS_DRAFT), true)
	EQUINOX_FLAGS := --draft $(EQUINOX_FLAGS)
endif

.PHONY: all
all: cloudflared test

.PHONY: cloudflared
cloudflared:
	go build -v $(VERSION_FLAGS) $(IMPORT_PATH)/cmd/cloudflared

.PHONY: test
test:
	go test -v -race $(VERSION_FLAGS) ./...

.PHONY: cloudflared-deb
cloudflared-deb: cloudflared
	mkdir -p $(PACKAGE_DIR)
	cp cloudflared $(PACKAGE_DIR)/cloudflared
	fakeroot fpm -C $(PACKAGE_DIR) -s dir -t deb --deb-compression bzip2 \
		-a $(GOARCH) -v $(VERSION) -n cloudflared

.PHONY: release
release: bin/equinox
	bin/equinox release $(EQUINOX_FLAGS) -- $(VERSION_FLAGS) $(IMPORT_PATH)/cmd/cloudflared

bin/equinox:
	mkdir -p bin
	curl -s https://bin.equinox.io/c/75JtLRTsJ3n/release-tool-beta-$(EQUINOX_PLATFORM).tgz | tar xz -C bin/
