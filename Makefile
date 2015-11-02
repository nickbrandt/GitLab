PREFIX=/usr/local
VERSION=$(shell git describe)-$(shell date -u +%Y%m%d.%H%M%S)

gitlab-workhorse: main.go githandler.go archive.go git-http.go helpers.go lfs.go
	go build -ldflags "-X main.Version ${VERSION}" -o gitlab-workhorse

install: gitlab-workhorse
	install gitlab-workhorse ${PREFIX}/bin/

.PHONY: test
test: test/data/test.git
	go test

test/data/test.git: test/data
	git clone --bare https://gitlab.com/gitlab-org/gitlab-test.git test/data/test.git

test/data:
	mkdir -p test/data

.PHONY: clean
clean:
	rm -f gitlab-workhorse
	rm -rf test/data test/scratch
