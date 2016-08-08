PREFIX=/usr/local
VERSION=$(shell git describe)-$(shell date -u +%Y%m%d.%H%M%S)
export GOPATH=$(shell pwd)/_build
GOBUILD=go build -ldflags "-X main.Version=${VERSION}"
PKG=gitlab.com/gitlab-org/gitlab-workhorse

all: clean-build gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse

gitlab-zip-cat:	_build $(shell find cmd/gitlab-zip-cat/ -name '*.go')
	${GOBUILD} -o $@ ${PKG}/cmd/$@
	
gitlab-zip-metadata:	_build $(shell find cmd/gitlab-zip-metadata/ -name '*.go')
	${GOBUILD} -o $@ ${PKG}/cmd/$@

gitlab-workhorse: _build $(shell find . -name '*.go' | grep -v '^\./_')
	${GOBUILD} -o $@ ${PKG}

install: gitlab-workhorse gitlab-zip-cat gitlab-zip-metadata
	mkdir -p $(DESTDIR)${PREFIX}/bin/
	install gitlab-workhorse gitlab-zip-cat gitlab-zip-metadata ${DESTDIR}${PREFIX}/bin/

_build:
	mkdir -p $@/src/${PKG}
	tar -cf - --exclude $@ --exclude .git . | (cd $@/src/${PKG} && tar -xf -)
	touch $@

.PHONY: test
test:	clean-build clean-workhorse all
	go fmt ${PKG}/... | awk '{ print } END { if (NR > 0) { print "Please run go fmt"; exit 1 } }'
	_support/path go test ${PKG}/...
	@echo SUCCESS

coverage:
	go test -cover -coverprofile=test.coverage
	go tool cover -html=test.coverage -o coverage.html
	rm -f test.coverage

fmt:
	go fmt ./...

.PHONY: clean
clean:	clean-workhorse clean-build
	rm -rf testdata/data testdata/scratch

.PHONY:	clean-workhorse
clean-workhorse:
	rm -f gitlab-workhorse gitlab-zip-cat gitlab-zip-metadata

.PHONY:	clean-build
clean-build:
	rm -rf _build
