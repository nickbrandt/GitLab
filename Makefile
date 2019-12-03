PREFIX=/usr/local
PKG := gitlab.com/gitlab-org/gitlab-workhorse
BUILD_DIR ?= $(CURDIR)
TARGET_DIR ?= $(BUILD_DIR)/_build
TARGET_SETUP := $(TARGET_DIR)/.ok
BIN_BUILD_DIR := $(TARGET_DIR)/bin
COVERAGE_DIR := $(TARGET_DIR)/cover
VERSION_STRING := $(shell git describe)
ifeq ($(strip $(VERSION_STRING)),)
VERSION_STRING := v$(shell cat VERSION)
endif
BUILD_TIME := $(shell date -u +%Y%m%d.%H%M%S)
GOBUILD := go build -ldflags "-X main.Version=$(VERSION_STRING) -X main.BuildTime=$(BUILD_TIME)"
EXE_ALL := gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse
INSTALL := install
BUILD_TAGS := tracer_static tracer_static_jaeger

MINIMUM_SUPPORTED_GO_VERSION := 1.11

export GOBIN := $(TARGET_DIR)/bin
export PATH := $(GOBIN):$(PATH)
export GOPROXY ?= https://proxy.golang.org
export GO111MODULE=on

LOCAL_GO_FILES = $(shell find . -type f -name '*.go' | grep -v -e /_ -e /testdata/)

define message
	@echo "### $(1)"
endef


.NOTPARALLEL:

.PHONY:	all
all:	clean-build $(EXE_ALL)

$(TARGET_SETUP):
	$(call message,"Setting up target directory")
	rm -rf "$(TARGET_DIR)"
	mkdir -p "$(TARGET_DIR)"
	touch "$(TARGET_SETUP)"

gitlab-zip-cat:	$(TARGET_SETUP) $(shell find cmd/gitlab-zip-cat/ -name '*.go')
	$(call message,Building $@)
	$(GOBUILD) -tags "$(BUILD_TAGS)" -o $(BUILD_DIR)/$@ $(PKG)/cmd/$@

gitlab-zip-metadata:	$(TARGET_SETUP) $(shell find cmd/gitlab-zip-metadata/ -name '*.go')
	$(call message,Building $@)
	$(GOBUILD) -tags "$(BUILD_TAGS)" -o $(BUILD_DIR)/$@ $(PKG)/cmd/$@

gitlab-workhorse:	$(TARGET_SETUP) $(shell find . -name '*.go' | grep -v '^\./_')
	$(call message,Building $@)
	$(GOBUILD) -tags "$(BUILD_TAGS)" -o $(BUILD_DIR)/$@ $(PKG)

.PHONY:	install
install:	gitlab-workhorse gitlab-zip-cat gitlab-zip-metadata
	$(call message,$@)
	mkdir -p $(DESTDIR)$(PREFIX)/bin/
	cd $(BUILD_DIR) && $(INSTALL) gitlab-workhorse gitlab-zip-cat gitlab-zip-metadata $(DESTDIR)$(PREFIX)/bin/

.PHONY:	test
test: $(TARGET_SETUP) prepare-tests
	$(call message,$@)
	@go test -tags "$(BUILD_TAGS)" ./...
	@echo SUCCESS

.PHONY:	coverage
coverage:	$(TARGET_SETUP) prepare-tests
	$(call message,$@)
	@go test -tags "$(BUILD_TAGS)" -cover -coverprofile=test.coverage ./...
	go tool cover -html=test.coverage -o coverage.html
	rm -f test.coverage

.PHONY:	clean
clean:	clean-workhorse clean-build
	$(call message,$@)
	rm -rf testdata/data testdata/scratch

.PHONY:	clean-workhorse
clean-workhorse:
	$(call message,$@)
	rm -f $(EXE_ALL)

.PHONY:	tag
tag:
	$(call message,$@)
	sh _support/tag.sh

.PHONY:	signed_tag
signed_tag:
	$(call message,$@)
	TAG_OPTS=-s sh _support/tag.sh

.PHONY:	clean-build
clean-build:
	$(call message,$@)
	rm -rf $(TARGET_DIR)

.PHONY:	prepare-tests
prepare-tests:	testdata/data/group/test.git $(EXE_ALL)

testdata/data/group/test.git:
	$(call message,$@)
	git clone --quiet --bare https://gitlab.com/gitlab-org/gitlab-test.git $@

.PHONY: verify
verify: lint vet detect-context check-formatting staticcheck

.PHONY: lint
lint: $(TARGET_SETUP)
	$(call message,Verify: $@)
	go install golang.org/x/lint/golint
	@_support/lint.sh ./...

.PHONY: vet
vet: $(TARGET_SETUP) 
	$(call message,Verify: $@)
	@go vet ./...

.PHONY: detect-context
detect-context: $(TARGET_SETUP)
	$(call message,Verify: $@)
	_support/detect-context.sh

.PHONY: check-formatting
check-formatting: $(TARGET_SETUP) install-goimports
	$(call message,Verify: $@)
	@_support/validate-formatting.sh $(LOCAL_GO_FILES)

# Megacheck will tailor some responses given a minimum Go version, so pass that through the CLI
# Additionally, megacheck will not return failure exit codes unless explicitly told to via the
# `-simple.exit-non-zero` `-unused.exit-non-zero` and `-staticcheck.exit-non-zero` flags
.PHONY: staticcheck
staticcheck: $(TARGET_SETUP)
	$(call message,Verify: $@)
	go install honnef.co/go/tools/cmd/staticcheck
	@ $(GOBIN)/staticcheck -go $(MINIMUM_SUPPORTED_GO_VERSION) ./...

# In addition to fixing imports, goimports also formats your code in the same style as gofmt
# so it can be used as a replacement.
.PHONY: fmt
fmt: $(TARGET_SETUP) install-goimports
	$(call message,$@)
	@goimports -w -local $(PKG) -l $(LOCAL_GO_FILES)

.PHONY:	goimports
install-goimports:	$(TARGET_SETUP)
	$(call message,$@)
	go install golang.org/x/tools/cmd/goimports
