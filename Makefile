PREFIX=/usr/local
VERSION=$(shell git describe)-$(shell date -u +%Y%m%d.%H%M%S)

gitlab-git-http-server: main.go githandler.go
	go build -ldflags "-X main.Version ${VERSION}" -o gitlab-git-http-server

install: gitlab-git-http-server
	install gitlab-git-http-server ${PREFIX}/bin/

.PHONY: test
test: test/data/test.git
	go test

test/data/test.git: test/data
	git clone --bare https://gitlab.com/gitlab-org/gitlab-test.git test/data/test.git

test/data:
	mkdir -p test/data

.PHONY: clean
clean:
	rm -f gitlab-git-http-server
	rm -rf test/data test/scratch
