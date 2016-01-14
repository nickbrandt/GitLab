PREFIX=/usr/local
VERSION=$(shell git describe)-$(shell date -u +%Y%m%d.%H%M%S)

gitlab-workhorse: $(shell find . -name '*.go')
	go build -ldflags "-X main.Version=${VERSION}" -o gitlab-workhorse

install: gitlab-workhorse
	install gitlab-workhorse ${PREFIX}/bin/

.PHONY: test
test: testdata/data/group/test.git clean-workhorse gitlab-workhorse
	go fmt ./... | awk '{ print } END { if (NR > 0) { print "Please run go fmt"; exit 1 } }'
	go test ./...
	@echo SUCCESS

coverage: testdata/data/group/test.git
	go test -cover -coverprofile=test.coverage
	go tool cover -html=test.coverage -o coverage.html
	rm -f test.coverage

testdata/data/group/test.git: testdata/data
	git clone --bare https://gitlab.com/gitlab-org/gitlab-test.git $@

testdata/data:
	mkdir -p $@

.PHONY: clean
clean:	clean-workhorse
	rm -rf testdata/data testdata/scratch

.PHONY:	clean-workhorse
clean-workhorse:
	rm -f gitlab-workhorse
