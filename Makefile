PREFIX=/usr/local
VERSION=$(shell git describe)-$(shell date -u +%Y%m%d.%H%M%S)

gitlab-workhorse: $(wildcard *.go)
	go build -ldflags "-X main.Version=${VERSION}" -o gitlab-workhorse

install: gitlab-workhorse
	mkdir -p $(DESTDIR)${PREFIX}/bin/
	install gitlab-workhorse ${DESTDIR}${PREFIX}/bin/

.PHONY: test
test: test/data/group/test.git clean-workhorse gitlab-workhorse
	go fmt | awk '{ print "Please run go fmt"; exit 1 }'
	go test

coverage: test/data/group/test.git
	go test -cover -coverprofile=test.coverage
	go tool cover -html=test.coverage -o coverage.html
	rm -f test.coverage

test/data/group/test.git: test/data
	git clone --bare https://gitlab.com/gitlab-org/gitlab-test.git test/data/group/test.git

test/data:
	mkdir -p test/data

.PHONY: clean
clean:	clean-workhorse
	rm -rf test/data test/scratch

.PHONY:	clean-workhorse
clean-workhorse:
	rm -f gitlab-workhorse
