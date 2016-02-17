PREFIX=/usr/local
VERSION=$(shell git describe)-$(shell date -u +%Y%m%d.%H%M%S)
GOBUILD=go build -ldflags "-X main.Version=${VERSION}"

all: gitlab-zip-cat gitlab-zip-metadata gitlab-workhorse

gitlab-zip-cat:	$(shell find cmd/gitlab-zip-cat/ -name '*.go')
	${GOBUILD} -o $@ ./cmd/$@
	
gitlab-zip-metadata:	$(shell find cmd/gitlab-zip-metadata/ -name '*.go')
	${GOBUILD} -o $@ ./cmd/$@

gitlab-workhorse: $(shell find . -name '*.go')
	${GOBUILD} -o $@

install: gitlab-workhorse gitlab-zip-cat gitlab-zip-metadata
	mkdir -p $(DESTDIR)${PREFIX}/bin/
	install gitlab-workhorse gitlab-zip-cat gitlab-zip-metadata ${DESTDIR}${PREFIX}/bin/

.PHONY: test
test: testdata/data/group/test.git clean-workhorse all
	go fmt ./... | awk '{ print } END { if (NR > 0) { print "Please run go fmt"; exit 1 } }'
	support/path go test ./...
	@echo SUCCESS

coverage: testdata/data/group/test.git
	go test -cover -coverprofile=test.coverage
	go tool cover -html=test.coverage -o coverage.html
	rm -f test.coverage

fmt:
	go fmt ./...

testdata/data/group/test.git: testdata/data
	git clone --bare https://gitlab.com/gitlab-org/gitlab-test.git $@

testdata/data:
	mkdir -p $@

.PHONY: clean
clean:	clean-workhorse
	rm -rf testdata/data testdata/scratch

.PHONY:	clean-workhorse
clean-workhorse:
	rm -f gitlab-workhorse gitlab-zip-cat gitlab-zip-metadata
